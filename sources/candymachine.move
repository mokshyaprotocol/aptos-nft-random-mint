module candymachine::candymachine{
    use std::signer;
    use std::bcs;
    use std::hash;
    use aptos_std::aptos_hash;
    use aptos_std::from_bcs;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::aptos_coin::AptosCoin;
    use std::error;
    use std::bit_vector::{Self,BitVector};
    use aptos_framework::coin::{Self};
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_token::token::{Self,TokenDataId,TokenId};
    use candymachine::bucket_table::{Self, BucketTable};
    use candymachine::merkle_proof::{Self};
    // use aptos_std::aptos_hash;

    const INVALID_SIGNER: u64 = 0;
    const INVALID_amount: u64 = 1;
    const CANNOT_ZERO: u64 = 2;
    const EINVALID_ROYALTY_NUMERATOR_DENOMINATOR: u64 = 3;
    const ESALE_NOT_STARTED: u64 = 4;
    const ESOLD_OUT:u64 = 5;
    const EPAUSED:u64 = 6;
    const INVALID_MUTABLE_CONFIG:u64 = 7;
    const EINVALID_MINT_TIME:u64 = 8;
    const MINT_LIMIT_EXCEED: u64 = 9;

     struct MintData has key {
        total_mints: u64,
        total_apt: u64
    }
    struct CandyMachine has key {
        collection_name: String,
        collection_description: String,
        baseuri: String,
        royalty_payee_address:address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        presale_mint_time: u64,
        public_sale_mint_time: u64,
        presale_mint_price: u64,
        public_sale_mint_price: u64,
        paused: bool,
        total_supply: u64,
        minted: u64,
        token_mutate_setting:vector<bool>,
        candies:vector<BitVector>,
        public_mint_limit: u64,
        merkle_root: vector<u8>
    }
    struct Whitelist has key {
        whitelist: BucketTable<address,u64>,
    }
    struct PublicMinters has key {
        minters: BucketTable<address, u64>,
    }
    struct ResourceInfo has key {
            source: address,
            resource_cap: account::SignerCapability
    }
    fun init_module(account: &signer) {
        move_to(account, MintData {
            total_mints: 0,
            total_apt: 0
        })
    }
    public entry fun init_candy(
        account: &signer,
        collection_name: String,
        collection_description: String,
        baseuri: String,
        royalty_payee_address:address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        presale_mint_time: u64,
        public_sale_mint_time: u64,
        presale_mint_price: u64,
        public_sale_mint_price: u64,
        total_supply:u64,
        collection_mutate_setting:vector<bool>,
        token_mutate_setting:vector<bool>,
        public_mint_limit: u64,
        merkle_root: vector<u8>,
        seeds: vector<u8>
    ){
        let (_resource, resource_cap) = account::create_resource_account(account, seeds);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_cap);
        let now = aptos_framework::timestamp::now_seconds();
        move_to<ResourceInfo>(&resource_signer_from_cap, ResourceInfo{resource_cap: resource_cap, source: signer::address_of(account)});
        assert!(vector::length(&collection_mutate_setting) == 3 && vector::length(&token_mutate_setting) == 5, error::invalid_argument(INVALID_MUTABLE_CONFIG));
        assert!(royalty_points_denominator > 0, error::invalid_argument(EINVALID_ROYALTY_NUMERATOR_DENOMINATOR));
        assert!(public_sale_mint_time >=  now && presale_mint_time >= now, error::invalid_argument(EINVALID_MINT_TIME));
        assert!(royalty_points_numerator <= royalty_points_denominator, error::invalid_argument(EINVALID_ROYALTY_NUMERATOR_DENOMINATOR));
        let candies_data = create_bit_mask(total_supply);
        move_to<CandyMachine>(&resource_signer_from_cap, CandyMachine{
            collection_name,
            collection_description,
            baseuri,
            royalty_payee_address,
            royalty_points_denominator,
            royalty_points_numerator,
            presale_mint_time,
            public_sale_mint_time,
            presale_mint_price,
            public_sale_mint_price,
            total_supply,
            minted:0,
            paused:false,
            candies:candies_data,
            token_mutate_setting,
            public_mint_limit: public_mint_limit,
            merkle_root
        });
        
 
        
        token::create_collection(
            &resource_signer_from_cap, 
            collection_name, 
            collection_description, 
            baseuri, 
            0,
            collection_mutate_setting
        );
    }
    public entry fun create_whitelist(
        account: &signer,
        candymachine: address,
        whitelist_addresses: vector<address>,
        mint_limit: u64,
    )acquires ResourceInfo,Whitelist{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        if(!exists<Whitelist>(candymachine)){
            let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
            initialize_whitelist(resource_signer_from_cap)

        };
        let whitelist_addr = borrow_global_mut<Whitelist>(candymachine);
        let i = 0;
        while (i < vector::length(&whitelist_addresses)) {
            let addr = *vector::borrow(&whitelist_addresses, i);
            bucket_table::add(&mut whitelist_addr.whitelist, addr, mint_limit);
            i = i + 1;
        };
    }
    public entry fun mint_script(
        receiver: &signer,
        candymachine: address,
    )acquires ResourceInfo, CandyMachine,Whitelist,MintData,PublicMinters{
        let receiver_addr = signer::address_of(receiver);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        let mint_data = borrow_global_mut<MintData>(@candymachine);
        let now = aptos_framework::timestamp::now_seconds();
        let mint_price = candy_data.public_sale_mint_price;
        if(exists<Whitelist>(candymachine) && candy_data.presale_mint_time < now && now < candy_data.public_sale_mint_time){
            let whitelist_data = borrow_global_mut<Whitelist>(candymachine);
            if (bucket_table::contains(&whitelist_data.whitelist, &receiver_addr)){
                let remaining_mint_limit = bucket_table::borrow_mut(&mut whitelist_data.whitelist, receiver_addr);
                assert!(*remaining_mint_limit != 0, MINT_LIMIT_EXCEED);
                *remaining_mint_limit = *remaining_mint_limit - 1;
                mint_data.total_apt=candy_data.presale_mint_price;
                mint_price = candy_data.presale_mint_price;
            }
        };
        mint(receiver,candymachine,mint_price)
    }
    public entry fun mint_from_merkle(
        receiver: &signer,
        candymachine: address,
        proof: vector<vector<u8>>,
        mint_limit: u64
    ) acquires ResourceInfo, CandyMachine,Whitelist,MintData,PublicMinters{
        let receiver_addr = signer::address_of(receiver);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        let mint_data = borrow_global_mut<MintData>(@candymachine);
        let now = aptos_framework::timestamp::now_seconds();
        let leafvec = bcs::to_bytes(&receiver_addr);
        vector::append(&mut leafvec,bcs::to_bytes(&mint_limit));
        assert!(merkle_proof::verify(proof,candy_data.merkle_root,aptos_hash::keccak256(aptos_hash::keccak256(leafvec))), error::invalid_argument(INVALID_MUTABLE_CONFIG));
        let is_whitelist_mint = candy_data.presale_mint_time < now && now < candy_data.public_sale_mint_time;
        if(!exists<Whitelist>(candymachine)){
            initialize_whitelist(resource_signer_from_cap)
        };
        let mint_price = candy_data.public_sale_mint_price;
        if(is_whitelist_mint){
            let whitelist_data = borrow_global_mut<Whitelist>(candymachine);
            if (!bucket_table::contains(&whitelist_data.whitelist, &receiver_addr)) {
                    bucket_table::add(&mut whitelist_data.whitelist, receiver_addr, mint_limit);
            };
            // add check for public mint limit
            let minted_nft = bucket_table::borrow_mut(&mut whitelist_data.whitelist, receiver_addr);
            assert!(*minted_nft == mint_limit, MINT_LIMIT_EXCEED);
            mint_data.total_apt=candy_data.presale_mint_price;
            mint_price = candy_data.presale_mint_price
        };
        mint(receiver,candymachine,mint_price)
    }
    fun mint(
        receiver: &signer,
        candymachine: address,
        mint_price: u64
    )acquires ResourceInfo, CandyMachine,PublicMinters,MintData{
        let receiver_addr = signer::address_of(receiver);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        let mint_data = borrow_global_mut<MintData>(@candymachine);
        let now = aptos_framework::timestamp::now_seconds();
        
        if(candy_data.public_sale_mint_price == mint_price){
            initialize_and_create_public_minter(&resource_signer_from_cap,candy_data,receiver_addr,candymachine);
            // mint_data.total_apt=candy_data.public_sale_mint_price;
        };
        assert!(candy_data.paused == false, EPAUSED);
        assert!(now > candy_data.presale_mint_time, ESALE_NOT_STARTED);
        assert!(candy_data.minted != candy_data.total_supply, ESOLD_OUT);
        assert!(now > candy_data.presale_mint_time, ESALE_NOT_STARTED);
        let remaining = candy_data.total_supply - candy_data.minted;
        let random_index = pseudo_random(receiver_addr,remaining);
        let required_position=0; // the number of unset 
        let bucket =0; // number of buckets
        let pos=0; // the mint number 
        let new =  vector::empty();
        while (required_position < random_index)
        {
        let bitvector=*vector::borrow_mut(&mut candy_data.candies, bucket);
        let i =0;
        while (i < bit_vector::length(&bitvector)) {
            if (!bit_vector::is_index_set(&bitvector, i))
            {
            required_position=required_position+1;
            };
            if (required_position == random_index)
            {
                bit_vector::set(&mut bitvector,i);
                vector::push_back(&mut new, bitvector);
                break
            };
            pos=pos+1;
            i= i + 1;
        };
        vector::push_back(&mut new, bitvector);
        bucket=bucket+1
        };
        while (bucket < vector::length(&candy_data.candies))
        {
            let bitvector=*vector::borrow_mut(&mut candy_data.candies, bucket);
            vector::push_back(&mut new, bitvector);
            bucket=bucket+1;
        };
        let mint_position = pos;
        candy_data.candies = new;
        let baseuri = candy_data.baseuri;
        let properties = vector::empty<String>();
        string::append(&mut baseuri,num_str(mint_position));
        
        let token_name = candy_data.collection_name;
        string::append(&mut token_name,string::utf8(b" #"));
        string::append(&mut token_name,num_str(mint_position));
        string::append(&mut baseuri,string::utf8(b".json"));
        let token_mut_config = token::create_token_mutability_config(&candy_data.token_mutate_setting);
        token::create_tokendata(
            &resource_signer_from_cap,
            candy_data.collection_name,
            token_name,
            candy_data.collection_description,
            1,
            baseuri,
            candy_data.royalty_payee_address,
            candy_data.royalty_points_denominator,
            candy_data.royalty_points_numerator,
            token_mut_config,
            properties,
            vector<vector<u8>>[],
            properties
        );
        let token_data_id = token::create_token_data_id(candymachine,candy_data.collection_name,token_name);
        token::opt_in_direct_transfer(receiver,true);
        coin::transfer<AptosCoin>(receiver, resource_data.source, mint_price);
        token::mint_token_to(
            &resource_signer_from_cap,
            receiver_addr,
            token_data_id,
            1
            );
        candy_data.minted=candy_data.minted+1;
        mint_data.total_mints=mint_data.total_mints+1
    }
    public entry fun pause_mint(
        account: &signer,
        candymachine: address,
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        candy_data.paused = true;
    }
    public entry fun resume_mint(
        account: &signer,
        candymachine: address,
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        candy_data.paused = false;
    }
    public entry fun update_candy(
        account: &signer,
        candymachine: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        presale_mint_time: u64,
        public_sale_mint_price: u64,
        presale_mint_price: u64,
        public_sale_mint_time: u64,
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let now = aptos_framework::timestamp::now_seconds();
        assert!(public_sale_mint_time >=  now && presale_mint_time >= now, error::invalid_argument(EINVALID_MINT_TIME));
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        assert!(royalty_points_denominator == 0, EINVALID_ROYALTY_NUMERATOR_DENOMINATOR);
        if (royalty_points_denominator>0){
            candy_data.royalty_points_denominator = royalty_points_denominator
        };
        if (royalty_points_numerator>0){
            candy_data.royalty_points_numerator = royalty_points_numerator
        };
        if (presale_mint_time>0){
            candy_data.presale_mint_time = presale_mint_time
        };
        if (public_sale_mint_time>0){
            candy_data.public_sale_mint_time = public_sale_mint_time
        };
        if (candy_data.public_sale_mint_price==0 || candy_data.presale_mint_price==0){
            if (public_sale_mint_price>0){
                candy_data.royalty_points_numerator = royalty_points_numerator
            };
            if (presale_mint_price>0){
                candy_data.royalty_points_numerator = royalty_points_numerator
            };
        };
        if (public_sale_mint_price>0){
            candy_data.presale_mint_price = presale_mint_price
        };
         if (public_sale_mint_price>0){
            candy_data.public_sale_mint_price = public_sale_mint_price
        };
    }
    public fun mutate_one_token(
        account: &signer,
        token_owner: address,
        token_id: TokenId,
        keys: vector<String>,
        values: vector<vector<u8>>,
        types: vector<String>,
        candymachine: address,
    )acquires ResourceInfo
    {
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        token::mutate_one_token(&resource_signer_from_cap,token_owner,token_id,keys,values,types);
    }
    public fun mutate_tokendata_uri(
        account: &signer,
        token_data_id: TokenDataId,
        uri: String,
        candymachine: address,
    )acquires ResourceInfo
    {
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        token::mutate_tokendata_uri(&resource_signer_from_cap,token_data_id,uri);
    }
    public fun mutate_tokendata_property(
        account: &signer,
        token_data_id: TokenDataId,
        keys: vector<String>,
        values: vector<vector<u8>>,
        types: vector<String>,
        candymachine: address
    )acquires ResourceInfo
    {
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        token::mutate_tokendata_property(&resource_signer_from_cap,token_data_id,keys,values,types);  
    }

    fun num_str(num: u64): String
    {
        let v1 = vector::empty();
        while (num/10 > 0){
            let rem = num%10;
            vector::push_back(&mut v1, (rem+48 as u8));
            num = num/10;
        };
        vector::push_back(&mut v1, (num+48 as u8));
        vector::reverse(&mut v1);
        string::utf8(v1)
    }

    fun create_bit_mask(nfts: u64): vector<BitVector>
    {
        let full_buckets = nfts/1024; 
        let remaining =nfts-full_buckets*1024; 
        if (nfts < 1024)
        {
            full_buckets=0;
            remaining= nfts;
        };
        let v1 = vector::empty();
        while (full_buckets>0)
        {
            let new = bit_vector::new(1023); 
            vector::push_back(&mut v1, new);
            full_buckets=full_buckets-1;
        };
        vector::push_back(&mut v1,bit_vector::new(remaining));
        v1
    }

    fun pseudo_random(add:address,remaining:u64):u64
    {
        let x = bcs::to_bytes<address>(&add);
        let y = bcs::to_bytes<u64>(&remaining);
        let z = bcs::to_bytes<u64>(&timestamp::now_seconds());
        vector::append(&mut x,y);
        vector::append(&mut x,z);
        let tmp = hash::sha2_256(x);

        let data = vector<u8>[];
        let i =24;
        while (i < 32)
        {
            let x =vector::borrow(&tmp,i);
            vector::append(&mut data,vector<u8>[*x]);
            i= i+1;
        };
        assert!(remaining>0,999);

        let random = from_bcs::to_u64(data) % remaining + 1;
        if (random == 0 )
        {
            random = 1;
        };
        random
    }

    fun initialize_whitelist(account: signer){
        move_to(&account, Whitelist {
            whitelist: bucket_table::new<address, u64>(4),
        })
    }

    fun initialize_and_create_public_minter(resource_signer_from_cap:&signer,candy_data: &mut CandyMachine,receiver_addr: address,candymachine:address)acquires PublicMinters{
        if (!exists<PublicMinters>(candymachine)) {
                move_to(resource_signer_from_cap, PublicMinters {
                // Can use a different size of bucket table depending on how big we expect the whitelist to be.
                // Here because a global pubic minting max is optional, we are starting with a smaller size
                // bucket table.
                minters: bucket_table::new<address, u64>(4),
                })
            };
            if(candy_data.public_mint_limit != 0){
                let public_minters= borrow_global_mut<PublicMinters>(candymachine);
                if (!bucket_table::contains(&public_minters.minters, &receiver_addr)) {
                        bucket_table::add(&mut public_minters.minters, receiver_addr, candy_data.public_mint_limit);
                };
                // add check for public mint limit
                let public_minters_limit= bucket_table::borrow_mut(&mut public_minters.minters, receiver_addr);
                assert!(*public_minters_limit != 0, MINT_LIMIT_EXCEED);
                *public_minters_limit = *public_minters_limit - 1;
            };
    }
    #[test_only]
    public fun init_module_for_test(account: &signer) {
        init_module(account);
    }
    #[test_only]
    public fun set_up_test(
        account: &signer,
        creator: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer,
        timestamp: u64
    )
    {
        init_module(account);
        let add1=  x"d4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77";
        let add2 = x"5f16f4c7f149ac4f9510d9cf8cf384038ad348b3bcdc01915f95de12df9d1b02";
        let mint_limit = 5;
        vector::append(&mut add1,bcs::to_bytes(&mint_limit));
        vector::append(&mut add2,bcs::to_bytes(&mint_limit));
        let leaf1 = aptos_hash::keccak256(add1);
        let leaf2 = aptos_hash::keccak256(add2);
        let root = merkle_proof::find_root(leaf1,leaf2);
        account::create_account_for_test(signer::address_of(creator));
        account::create_account_for_test(signer::address_of(minter));
        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(aptos_framework);
        coin::register<0x1::aptos_coin::AptosCoin>(minter);
        coin::register<0x1::aptos_coin::AptosCoin>(creator);
        coin::deposit(signer::address_of(minter), coin::mint(10000, &mint_cap));
        coin::deposit(signer::address_of(creator), coin::mint(1000, &mint_cap));
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
        aptos_framework::timestamp::set_time_has_started_for_testing(candymachine);
        aptos_framework::timestamp::update_global_time_for_test_secs(timestamp);
        init_candy(
                creator,
                string::utf8(b"Collection: Mokshya"),
                string::utf8(b"Collection: Mokshya"),
                string::utf8(b"https://mokshya.io"),
                signer::address_of(creator),
                100,
                0,
                80,
                100,
                100,
                0,
                100,
                vector<bool>[false, false, false],
                vector<bool>[false, false, false, false, false],
                0,
                root,
                b"candy"
            );
            init_candy(
                creator,
                string::utf8(b"Collection: Mokshya"),
                string::utf8(b"Collection: Mokshya"),
                string::utf8(b"https://mokshya.io"),
                signer::address_of(creator),
                100,
                0,
                80,
                100,
                100,
                0,
                100,
                vector<bool>[false, false, false],
                vector<bool>[false, false, false, false, false],
                1,
                b"FAKEROOT",
                b"candy_with_data"
            );
    }
    #[test(creator = @0xb0c, minter = @0xd4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77, candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine)]
    public entry fun test_candy_machine(
            creator: &signer,
            account: &signer,
            aptos_framework: &signer,
            minter: &signer,
            candymachine: &signer
        )acquires ResourceInfo,CandyMachine,Whitelist,PublicMinters,MintData
        {
            let add1=  x"d4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77";
            let add2 = x"5f16f4c7f149ac4f9510d9cf8cf384038ad348b3bcdc01915f95de12df9d1b02";
            let mint_limit = 5;
            vector::append(&mut add1,bcs::to_bytes(&mint_limit));
            vector::append(&mut add2,bcs::to_bytes(&mint_limit));
            let _leaf1 = aptos_hash::keccak256(add1);
            let leaf2 = aptos_hash::keccak256(add2);
            set_up_test(account,creator,aptos_framework,minter,candymachine,80);
            aptos_framework::timestamp::update_global_time_for_test_secs(102);
            let whitelist_address= vector<address>[signer::address_of(minter)];
            let mint_limit= 1;
            let candy_machine = account::create_resource_address(&signer::address_of(creator), b"candy");
            create_whitelist(
                creator,
                candy_machine,
                whitelist_address,
                mint_limit,
            );
            // mint_script(
            //     minter,
            //     candy_machine
            // );
            aptos_framework::timestamp::update_global_time_for_test_secs(200);
            let candy_machine_2 = account::create_resource_address(&signer::address_of(creator), b"candy_with_data");
            mint_script(
                minter,
                candy_machine_2
            );
            mint_from_merkle(
                minter,
                candy_machine,
                vector[leaf2],
                5
            )
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine)]
    public entry fun test_mint_all_tokens(
            creator: &signer,
            account: &signer,
            aptos_framework: &signer,
            minter: &signer,
            candymachine: &signer
        )acquires ResourceInfo,CandyMachine,Whitelist,PublicMinters,MintData
        {
            set_up_test(account,creator,aptos_framework,minter,candymachine,80);
            aptos_framework::timestamp::update_global_time_for_test_secs(102);
            let candy_machine = account::create_resource_address(&signer::address_of(creator), b"candy");
            let i = 0;
            while (i < 100) {
                mint_script(
                minter,
                candy_machine
                );
                i = i +1;
            }
        }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine)]
    #[expected_failure(abort_code = 0x10003, location = Self)]
    public entry fun test_royalty_overflow(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer
    )
    {
        set_up_test(account,creator,aptos_framework,minter,candymachine,80);
        init_candy(
            creator,
            string::utf8(b"Collection: Mokshya"),
            string::utf8(b"Collection: Mokshya"),
            string::utf8(b"https://mokshya.io"),
            signer::address_of(creator),
            10,
            100,
            100,
            100,
            100,
            0,
            100,
            vector<bool>[false, false, false],
            vector<bool>[false, false, false, false, false],
            1,
            b"FAKEROOT",
            b"royalty"
        );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine)]
    #[expected_failure(abort_code = 0x10008, location = Self)]
    public entry fun test_timestamp(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer
    )
    {
        set_up_test(account,creator,aptos_framework,minter,candymachine,80);
        init_candy(
            creator,
            string::utf8(b"Collection: Mokshya"),
            string::utf8(b"Collection: Mokshya"),
            string::utf8(b"https://mokshya.io"),
            signer::address_of(creator),
            10,
            100,
            1,
            1,
            100,
            0,
            100,
            vector<bool>[false, false, false],
            vector<bool>[false, false, false, false, false],
            1,
            b"FAKEROOT",
            b"royalty"
        );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine)]
    #[expected_failure(abort_code = 0x4, location = Self)]
    public entry fun test_mint_before_launch(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer
    )acquires ResourceInfo, CandyMachine,Whitelist,PublicMinters,MintData
    {
        set_up_test(account,creator,aptos_framework,minter,candymachine,80);
        let candy_machine = account::create_resource_address(&signer::address_of(creator), b"candy");
        mint_script(
            minter,
            candy_machine
        );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, minter2 = @0xc0d,candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine)]
    #[expected_failure(abort_code = 0x9, location = Self)]
    public entry fun test_mint_limit_whitelist(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        minter2: &signer,
        candymachine: &signer
    )acquires ResourceInfo, CandyMachine,Whitelist,PublicMinters,MintData
    {
        set_up_test(account,creator,aptos_framework,minter,candymachine,80);
        let candy_machine = account::create_resource_address(&signer::address_of(creator), b"candy");
        let mint_limit= 2;
        account::create_account_for_test(signer::address_of(minter2));
        coin::register<0x1::aptos_coin::AptosCoin>(minter2);
        coin::transfer<AptosCoin>(minter, signer::address_of(minter2), 300);
        let whitelist_addresses= vector<address>[signer::address_of(minter),signer::address_of(minter2)];
        create_whitelist(
            creator,
            candy_machine,
            whitelist_addresses,
            mint_limit,
        );
        aptos_framework::timestamp::update_global_time_for_test_secs(90);
        mint_script(
            minter,
            candy_machine
        );
        mint_script(
            minter,
            candy_machine
        );
        mint_script(
            minter2,
            candy_machine
        );
        mint_script(
            minter2,
            candy_machine
        );
        mint_script(
            minter2,
            candy_machine
        );
        mint(
            minter2,
            candy_machine,
            100
        );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, minter2 = @0xc0d,candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine)]
    #[expected_failure(abort_code = 0x9, location = Self)]
    public entry fun test_mint_limit_public(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        minter2: &signer,
        candymachine: &signer
    )acquires ResourceInfo, CandyMachine,Whitelist,PublicMinters,MintData
    {
        set_up_test(account,creator,aptos_framework,minter,candymachine,80);
        account::create_account_for_test(signer::address_of(minter2));
        coin::register<0x1::aptos_coin::AptosCoin>(minter2);
        coin::transfer<AptosCoin>(minter, signer::address_of(minter2), 300);
        aptos_framework::timestamp::update_global_time_for_test_secs(200);
        let candy_machine_2 = account::create_resource_address(&signer::address_of(creator), b"candy_with_data");
        mint_script(
            minter,
            candy_machine_2
        );
        mint_script(
            minter2,
            candy_machine_2
        );
        mint_script(
            minter,
            candy_machine_2
        );
        mint_script(
            minter2,
            candy_machine_2
        );
    }
}
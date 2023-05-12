module candymachine::candymachine{
    use std::signer;
    use std::bcs;
    use std::hash;
    use aptos_std::aptos_hash;
    use aptos_std::from_bcs;
    use std::string::{Self, String};
    use std::vector;
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::aptos_coin::AptosCoin;
    use candymachine::bit_vector::{Self,BitVector};
    use aptos_framework::coin::{Self};
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use aptos_token::token::{Self};
    use candymachine::bucket_table::{Self, BucketTable};
    use candymachine::merkle_proof::{Self};


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
    const INVALID_PROOF:u64 = 10;
    const WhitelistMintNotEnabled: u64 = 11;
    const MokshyaFee: address = @0x305d730682a5311fbfc729a51b8eec73924b40849bff25cf9fdb4348cc0a719a;

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
        candies:BitVector,
        public_mint_limit: u64,
        merkle_root: vector<u8>,
        update_event: EventHandle<UpdateCandyEvent>,
    }
    struct Whitelist has key {
        minters: BucketTable<address,u64>,
    }
    struct PublicMinters has key {
        minters: BucketTable<address, u64>,
    }
    struct ResourceInfo has key {
            source: address,
            resource_cap: account::SignerCapability
    }
    struct UpdateCandyEvent has drop, store {
        presale_mint_price: u64,
        presale_mint_time: u64,
        public_sale_mint_price: u64,
        public_sale_mint_time: u64,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
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
        seeds: vector<u8>
    ){
        let (_resource, resource_cap) = account::create_resource_account(account, seeds);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_cap);
        let now = aptos_framework::timestamp::now_seconds();
        move_to<ResourceInfo>(&resource_signer_from_cap, ResourceInfo{resource_cap: resource_cap, source: signer::address_of(account)});
        assert!(vector::length(&collection_mutate_setting) == 3 && vector::length(&token_mutate_setting) == 5, INVALID_MUTABLE_CONFIG);
        assert!(royalty_points_denominator > 0, EINVALID_ROYALTY_NUMERATOR_DENOMINATOR);
        assert!(public_sale_mint_time > presale_mint_time && presale_mint_time >= now,EINVALID_MINT_TIME);
        assert!(royalty_points_numerator <= royalty_points_denominator, EINVALID_ROYALTY_NUMERATOR_DENOMINATOR);
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
            candies:bit_vector::new(total_supply),
            token_mutate_setting,
            public_mint_limit: public_mint_limit,
            merkle_root: vector::empty(),
            update_event: account::new_event_handle<UpdateCandyEvent>(&resource_signer_from_cap),
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
    public entry fun mint_script(
        receiver: &signer,
        candymachine: address,
    )acquires ResourceInfo, CandyMachine,MintData,PublicMinters{
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        let mint_price = candy_data.public_sale_mint_price;
        let now = aptos_framework::timestamp::now_seconds();
        assert!(now > candy_data.public_sale_mint_time, ESALE_NOT_STARTED);
        mint(receiver,candymachine,mint_price)
    }
    public entry fun mint_from_merkle(
        receiver: &signer,
        candymachine: address,
        proof: vector<vector<u8>>,
        mint_limit: u64
    ) acquires ResourceInfo,MintData,PublicMinters,CandyMachine,Whitelist{
        let receiver_addr = signer::address_of(receiver);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let candy_data = borrow_global<CandyMachine>(candymachine);
        let mint_data = borrow_global_mut<MintData>(@candymachine);
        let now = aptos_framework::timestamp::now_seconds();
        let leafvec = bcs::to_bytes(&receiver_addr);
        vector::append(&mut leafvec,bcs::to_bytes(&mint_limit));
        let is_whitelist_mint = candy_data.presale_mint_time < now && now < candy_data.public_sale_mint_time;
        assert!(is_whitelist_mint, WhitelistMintNotEnabled);
        assert!(merkle_proof::verify(proof,candy_data.merkle_root,aptos_hash::keccak256(leafvec)),INVALID_PROOF);
        if(!exists<Whitelist>(candymachine)){
            initialize_whitelist(resource_signer_from_cap)
        };
        // No need to check limit if mint limit = 0, this means the minter can mint unlimited amount of tokens
        if(mint_limit != 0){
            let whitelist_data = borrow_global_mut<Whitelist>(candymachine);
            if (!bucket_table::contains(&whitelist_data.minters, &receiver_addr)) {
                // First time minting mint limit = 0 
                bucket_table::add(&mut whitelist_data.minters, receiver_addr, 0);
            };
            let minted_nft = bucket_table::borrow_mut(&mut whitelist_data.minters, receiver_addr);
            assert!(*minted_nft != mint_limit, MINT_LIMIT_EXCEED);
            *minted_nft = *minted_nft + 1;
            mint_data.total_apt=mint_data.total_apt+candy_data.presale_mint_price;
        };
        mint(receiver,candymachine,candy_data.presale_mint_price);
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
        if(now > candy_data.public_sale_mint_time && candy_data.public_mint_limit != 0){
            initialize_and_create_public_minter(&resource_signer_from_cap,candy_data,receiver_addr,candymachine);
            mint_data.total_apt=mint_data.total_apt+candy_data.public_sale_mint_price;
        };
        assert!(!candy_data.paused, EPAUSED);
        assert!(candy_data.minted != candy_data.total_supply, ESOLD_OUT);
        let remaining = candy_data.total_supply - candy_data.minted;
        let random_index = pseudo_random(receiver_addr,remaining);
        let required_position=0; // the number of unset 
        let pos=0; // the mint number 
        while (required_position < random_index)
        {
        if (!bit_vector::is_index_set(&candy_data.candies, pos))
            {
                required_position=required_position+1;

            };
        if (required_position == random_index)
            {                    
                break
            };
            pos=pos+1;
        };
        bit_vector::set(&mut candy_data.candies,pos);
        let mint_position = pos;
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
        let fee = (300*mint_price)/10000;
        let collection_owner_price = mint_price - fee;
        coin::transfer<AptosCoin>(receiver, MokshyaFee, fee);
        coin::transfer<AptosCoin>(receiver, resource_data.source, collection_owner_price);
        token::mint_token_to(
            &resource_signer_from_cap,
            receiver_addr,
            token_data_id,
            1
            );
        candy_data.minted=candy_data.minted+1;
        mint_data.total_mints=mint_data.total_mints+1
    }
    public entry fun set_root(account: &signer,candymachine: address,merkle_root: vector<u8>) acquires CandyMachine,ResourceInfo{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        candy_data.merkle_root = merkle_root
    }
    public entry fun pause_resume_mint(
        account: &signer,
        candymachine: address,
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        if(candy_data.paused == true){
            candy_data.paused = false
        }
        else {
            candy_data.paused = true
        }
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
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        if (royalty_points_denominator>0){
            candy_data.royalty_points_denominator = royalty_points_denominator
        };
        if (royalty_points_numerator>0){
            candy_data.royalty_points_numerator = royalty_points_numerator
        };
        if (presale_mint_time>0){
            assert!(presale_mint_time >= now,EINVALID_MINT_TIME);
            candy_data.presale_mint_time = presale_mint_time
        };
        if (public_sale_mint_time>0){
            assert!(public_sale_mint_time > candy_data.presale_mint_time,EINVALID_MINT_TIME);
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
        if (presale_mint_price>0){
            candy_data.presale_mint_price = presale_mint_price
        };
        if (public_sale_mint_price>0){
            candy_data.public_sale_mint_price = public_sale_mint_price
        };
        event::emit_event(&mut candy_data.update_event,UpdateCandyEvent {
                presale_mint_price: candy_data.presale_mint_price,
                presale_mint_time: candy_data.presale_mint_time,
                public_sale_mint_price: candy_data.public_sale_mint_price,
                public_sale_mint_time: candy_data.public_sale_mint_time,
                royalty_points_denominator: candy_data.royalty_points_denominator,
                royalty_points_numerator: candy_data.royalty_points_numerator,
            }
        );
    }
    public fun mutate_one_token(
        account: &signer,
        token_owner: address,
        token_name:String,
        property_version:u64,
        keys: vector<String>,
        values: vector<vector<u8>>,
        types: vector<String>,
        candymachine: address,
    )acquires ResourceInfo,CandyMachine
    {
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global<CandyMachine>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let token_id = token::create_token_id_raw(candymachine,candy_data.collection_name,token_name,property_version);
        token::mutate_one_token(&resource_signer_from_cap,token_owner,token_id,keys,values,types);
    }
    public fun mutate_tokendata_uri(
        account: &signer,
        token_name: String,
        uri: String,
        candymachine: address,
    )acquires ResourceInfo,CandyMachine
    {
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global<CandyMachine>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let token_data_id = token::create_token_data_id(candymachine,candy_data.collection_name,token_name);
        token::mutate_tokendata_uri(&resource_signer_from_cap,token_data_id,uri);
    }
    public fun mutate_tokendata_property(
        account: &signer,
        token_name:String,
        keys: vector<String>,
        values: vector<vector<u8>>,
        types: vector<String>,
        candymachine: address
    )acquires ResourceInfo,CandyMachine
    {
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global<CandyMachine>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let token_data_id = token::create_token_data_id(candymachine,candy_data.collection_name,token_name);
        token::mutate_tokendata_property(&resource_signer_from_cap,token_data_id,keys,values,types);  
    }
    public fun mutate_token_royalty(
        account: &signer,
        token_name:String,
        royalty_points_numerator:u64,
        royalty_points_denominator:u64,
        candymachine: address
    )acquires ResourceInfo,CandyMachine
    {
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global<CandyMachine>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let token_data_id = token::create_token_data_id(candymachine,candy_data.collection_name,token_name);
        let royalty = token::create_royalty(royalty_points_numerator, royalty_points_denominator, candy_data.royalty_payee_address);
        token::mutate_tokendata_royalty(&resource_signer_from_cap,token_data_id,royalty);
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
        random
    }

    fun initialize_whitelist(account: signer){
        move_to(&account, Whitelist {
            minters: bucket_table::new<address, u64>(4),
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
            let public_minters= borrow_global_mut<PublicMinters>(candymachine);
            if (!bucket_table::contains(&public_minters.minters, &receiver_addr)) {
                    bucket_table::add(&mut public_minters.minters, receiver_addr, candy_data.public_mint_limit);
            };
            // add check for public mint limit
            let public_minters_limit= bucket_table::borrow_mut(&mut public_minters.minters, receiver_addr);
            assert!(*public_minters_limit != 0, MINT_LIMIT_EXCEED);
            *public_minters_limit = *public_minters_limit - 1;
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
        fee_account: &signer,
        timestamp: u64,
        mint_limit: u64
    ) acquires CandyMachine,ResourceInfo
    {
        init_module(account);
        let add1=  x"d4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77";
        let add2 = x"5f16f4c7f149ac4f9510d9cf8cf384038ad348b3bcdc01915f95de12df9d1b02";
        vector::append(&mut add1,bcs::to_bytes(&mint_limit));
        vector::append(&mut add2,bcs::to_bytes(&mint_limit));
        let leaf1 = aptos_hash::keccak256(add1);
        let leaf2 = aptos_hash::keccak256(add2);
        let root = merkle_proof::find_root(leaf1,leaf2);
        account::create_account_for_test(signer::address_of(creator));
        account::create_account_for_test(MokshyaFee);
        account::create_account_for_test(signer::address_of(minter));
        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(aptos_framework);
        coin::register<0x1::aptos_coin::AptosCoin>(minter);
        coin::register<0x1::aptos_coin::AptosCoin>(fee_account);
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
                b"candy"
        );
        let candy_machine1 = account::create_resource_address(&signer::address_of(creator), b"candy");
        let candy_machine2 = account::create_resource_address(&signer::address_of(creator), b"candy_with_data");
        set_root(creator,candy_machine1,root);
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
            b"candy_with_data"
        );
        set_root(creator,candy_machine2,root)
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine,fee_account=@0x305d730682a5311fbfc729a51b8eec73924b40849bff25cf9fdb4348cc0a719a)]
    public entry fun test_mint_all_tokens(
            creator: &signer,
            account: &signer,
            aptos_framework: &signer,
            minter: &signer,
            candymachine: &signer,
            fee_account:&signer
        )acquires ResourceInfo,CandyMachine,PublicMinters,MintData
        {
            let mint_limit = 5;
            set_up_test(account,creator,aptos_framework,minter,candymachine,fee_account,80,mint_limit);
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
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine,fee_account=@0x305d730682a5311fbfc729a51b8eec73924b40849bff25cf9fdb4348cc0a719a)]
    #[expected_failure(abort_code = 0x3, location = Self)]
    public entry fun test_royalty_overflow(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer,
        fee_account: &signer
    ) acquires CandyMachine,ResourceInfo
    {
        let mint_limit = 5;
        set_up_test(account,creator,aptos_framework,minter,candymachine,fee_account,80,mint_limit);
        init_candy(
            creator,
            string::utf8(b"Collection: Mokshya"),
            string::utf8(b"Collection: Mokshya"),
            string::utf8(b"https://mokshya.io"),
            signer::address_of(creator),
            10,
            100,
            100,
            200,
            400,
            0,
            100,
            vector<bool>[false, false, false],
            vector<bool>[false, false, false, false, false],
            1,
            b"royalty"
        );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine,fee_account=@0x305d730682a5311fbfc729a51b8eec73924b40849bff25cf9fdb4348cc0a719a)]
    #[expected_failure(abort_code = 0x8, location = Self)]
    public entry fun test_timestamp(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer,
        fee_account: &signer
    )acquires CandyMachine,ResourceInfo
    {
        let mint_limit = 5;
        set_up_test(account,creator,aptos_framework,minter,candymachine,fee_account,80,mint_limit);
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
            b"royalty"
        );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine,fee_account=@0x305d730682a5311fbfc729a51b8eec73924b40849bff25cf9fdb4348cc0a719a)]
    #[expected_failure(abort_code = 0x4, location = Self)]
    public entry fun test_mint_before_launch(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer,
        fee_account: &signer
    )acquires ResourceInfo, CandyMachine,PublicMinters,MintData
    {
        let mint_limit = 5;
        set_up_test(account,creator,aptos_framework,minter,candymachine,fee_account,80,mint_limit);
        let candy_machine = account::create_resource_address(&signer::address_of(creator), b"candy");
        mint_script(
            minter,
            candy_machine
        );
    }
    #[test(creator = @0xb0c, minter = @0xd4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77, minter2 = @0xc0d,candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine,fee_account=@0x305d730682a5311fbfc729a51b8eec73924b40849bff25cf9fdb4348cc0a719a)]
    public entry fun test_mint_limit_whitelist(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        minter2: &signer,
        candymachine: &signer,
        fee_account: &signer
    )acquires ResourceInfo, CandyMachine,PublicMinters,MintData,Whitelist
    {
        let mint_limit = 5;
        set_up_test(account,creator,aptos_framework,minter,candymachine,fee_account,80,mint_limit);
        let candy_machine = account::create_resource_address(&signer::address_of(creator), b"candy");
        account::create_account_for_test(signer::address_of(minter2));
        coin::register<0x1::aptos_coin::AptosCoin>(minter2);
        coin::transfer<AptosCoin>(minter, signer::address_of(minter2), 300);
        aptos_framework::timestamp::update_global_time_for_test_secs(90);
        let add1=  x"d4dee0beab2d53f2cc83e567171bd2820e49898130a22622b10ead383e90bd77";
        let add2 = x"5f16f4c7f149ac4f9510d9cf8cf384038ad348b3bcdc01915f95de12df9d1b02";
        vector::append(&mut add1,bcs::to_bytes(&mint_limit));
        vector::append(&mut add2,bcs::to_bytes(&mint_limit));
        let leaf2 = aptos_hash::keccak256(add2);
        let i = 0;
        while(i < mint_limit){
            mint_from_merkle(
                minter,
                candy_machine,
                vector[leaf2],
                5
            );
            i = i + 1;
        }
    }
    #[test(creator = @0xb0c, minter = @0xc0c, minter2 = @0xc0d,candymachine=@0x1,aptos_framework = @aptos_framework,account=@candymachine,fee_account=@0x305d730682a5311fbfc729a51b8eec73924b40849bff25cf9fdb4348cc0a719a)]
    #[expected_failure(abort_code = 0x9, location = Self)]
    public entry fun test_mint_limit_public(
        creator: &signer,
        account: &signer,
        aptos_framework: &signer,
        minter: &signer,
        minter2: &signer,
        candymachine: &signer,
        fee_account: &signer
    )acquires ResourceInfo, CandyMachine,PublicMinters,MintData
    {
        set_up_test(account,creator,aptos_framework,minter,candymachine,fee_account,80,5);
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
    }
}
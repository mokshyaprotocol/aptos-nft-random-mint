module candymachine::candymachine{
    use std::signer;
    use std::bcs;
    use std::hash;
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


    const INVALID_SIGNER: u64 = 0;
    const INVALID_amount: u64 = 1;
    const CANNOT_ZERO: u64 = 2;
    const EINVALID_ROYALTY_NUMERATOR_DENOMINATOR: u64 = 3;
    const ESALE_NOT_STARTED: u64 = 4;
    const ESOLD_OUT:u64 = 5;
    const EPAUSED:u64 = 6;
    const INVALID_MUTABLE_CONFIG:u64 = 7;
    const EINVALID_MINT_TIME:u64 = 8;

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
        whitelist: vector<address>,
    }
    struct CandyMintingEvent has drop, store {
        token_id: TokenId,
    }
    struct Whitelist has key {
        whitelist: vector<address>,
    }
    struct ResourceInfo has key {
            source: address,
            resource_cap: account::SignerCapability
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
        let whitelist = vector::empty<address>();
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
            whitelist,
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
        whitelist: vector<address>,
        seeds:vector<u8>
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let (_whitelist_add, whitelist_cap) = account::create_resource_account(account, seeds);
        let whitelist_signer_from_cap = account::create_signer_with_capability(&whitelist_cap);
        vector::push_back(&mut candy_data.whitelist,signer::address_of(&whitelist_signer_from_cap));
        move_to<Whitelist>(&whitelist_signer_from_cap, Whitelist{whitelist});
    }
    public entry fun mint_script(
        receiver: &signer,
        candymachine: address,
    )acquires ResourceInfo, CandyMachine,Whitelist{
        let receiver_addr = signer::address_of(receiver);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        assert!(candy_data.paused == false, INVALID_SIGNER);
        assert!(candy_data.minted != candy_data.total_supply, ESOLD_OUT);
        let now = aptos_framework::timestamp::now_seconds();
        assert!(now > candy_data.presale_mint_time, ESALE_NOT_STARTED);
        let whitelist_accounts_len =  vector::length(&candy_data.whitelist);
        let i = 0;

        let remaining = candy_data.total_supply - candy_data.minted;
        let random_index = pseudo_random(receiver_addr,remaining);

        // let (mint_position,candies) = mint_available_number(random_index,candy_data.candies);
        // candy_data.candies = candies;
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
        let mint_price = candy_data.public_sale_mint_price;
        while (i < whitelist_accounts_len){
            let tmp = *vector::borrow(&candy_data.whitelist,i);
            let whitelist_data = borrow_global<Whitelist>(tmp);
            if (vector::contains(&whitelist_data.whitelist,&receiver_addr)){
                if (now > candy_data.presale_mint_time && now < candy_data.public_sale_mint_time ){
                    mint_price = candy_data.presale_mint_price
                };
            };
            i=i+1
        };
        if (mint_price == candy_data.public_sale_mint_price){
            assert!(now > candy_data.public_sale_mint_time, ESALE_NOT_STARTED);
        };
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
        candy_data.minted=candy_data.minted+1
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

    #[test_only]
    public fun set_up_test(
        creator: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer
    )
    {
        account::create_account_for_test(signer::address_of(creator));
        account::create_account_for_test(signer::address_of(minter));
        let (burn_cap, mint_cap) = aptos_framework::aptos_coin::initialize_for_test(aptos_framework);
        coin::register<0x1::aptos_coin::AptosCoin>(minter);
        coin::register<0x1::aptos_coin::AptosCoin>(creator);
        coin::deposit(signer::address_of(minter), coin::mint(100, &mint_cap));
        coin::deposit(signer::address_of(creator), coin::mint(100, &mint_cap));
        coin::destroy_burn_cap(burn_cap);
        coin::destroy_mint_cap(mint_cap);
        aptos_framework::timestamp::set_time_has_started_for_testing(candymachine);
        aptos_framework::timestamp::update_global_time_for_test_secs(100);
        init_candy(
                creator,
                string::utf8(b"Collection: Mokshya"),
                string::utf8(b"Collection: Mokshya"),
                string::utf8(b"https://mokshya.io"),
                signer::address_of(creator),
                100,
                0,
                100,
                100,
                100,
                0,
                100,
                vector<bool>[false, false, false],
                vector<bool>[false, false, false, false, false],
                b"candy"
            );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework)]
    public entry fun test_candy_machine(
            creator: &signer,
            aptos_framework: &signer,
            minter: &signer,
            candymachine: &signer
        )acquires ResourceInfo,CandyMachine,Whitelist
        {
            set_up_test(creator,aptos_framework,minter,candymachine);
            aptos_framework::timestamp::update_global_time_for_test_secs(102);
            let whitelist_address= vector<address>[signer::address_of(minter)];
            let candy_machine = account::create_resource_address(&signer::address_of(creator), b"candy");
            create_whitelist(
                creator,
                candy_machine,
                whitelist_address,
                b"whitelist",
            );
            mint_script(
                minter,
                candy_machine
            );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework)]
    public entry fun test_mint_all_tokens(
            creator: &signer,
            aptos_framework: &signer,
            minter: &signer,
            candymachine: &signer
        )acquires ResourceInfo,CandyMachine,Whitelist
        {
            set_up_test(creator,aptos_framework,minter,candymachine);
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
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 0x10003, location = Self)]
    public entry fun test_royalty_overflow(
        creator: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer
    )
    {
        set_up_test(creator,aptos_framework,minter,candymachine);
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
            b"royalty"
        );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 0x10008, location = Self)]
    public entry fun test_timestamp(
        creator: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer
    )
    {
        set_up_test(creator,aptos_framework,minter,candymachine);
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
            b"royalty"
        );
    }
    #[test(creator = @0xb0c, minter = @0xc0c, candymachine=@0x1,aptos_framework = @aptos_framework)]
    #[expected_failure(abort_code = 0x4, location = Self)]
    public entry fun test_mint_before_launch(
        creator: &signer,
        aptos_framework: &signer,
        minter: &signer,
        candymachine: &signer
    )acquires ResourceInfo, CandyMachine,Whitelist
    {
        set_up_test(creator,aptos_framework,minter,candymachine);
        let candy_machine = account::create_resource_address(&signer::address_of(creator), b"candy");
        mint_script(
            minter,
            candy_machine
        );
    }
}
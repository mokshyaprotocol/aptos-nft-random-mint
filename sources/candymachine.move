module candymachine::candymachine{
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    use std::error;
    use std::bcs;
    use aptos_framework::coin::{Self};
    use aptos_framework::account;
    use aptos_token::token::{Self,Royalty,TokenDataId,TokenId};
    use aptos_std::simple_map::{Self, SimpleMap};
    use aptos_std::any;
    use aptos_std::from_bcs;
    use aptos_std::copyable_any;
    const INVALID_SIGNER: u64 = 0;
    const INVALID_amount: u64 = 1;
    const CANNOT_ZERO: u64 = 2;
    const EINVALID_ROYALTY_NUMERATOR_DENOMINATOR: u64 = 3;
    const ESALE_NOT_STARTED: u64 = 4;
    const ESOLD_OUT:u64 = 5;
    const EPAUSED:u64 = 6;

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
        whitelist: vector<address>,
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
        let account_addr = signer::address_of(account);
        let (_resource, resource_cap) = account::create_resource_account(account, seeds);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_cap);
        move_to<ResourceInfo>(&resource_signer_from_cap, ResourceInfo{resource_cap: resource_cap, source: signer::address_of(account)});
        
        assert!(royalty_points_denominator > 0, error::invalid_argument(EINVALID_ROYALTY_NUMERATOR_DENOMINATOR));
        assert!(royalty_points_numerator <= royalty_points_denominator, error::invalid_argument(EINVALID_ROYALTY_NUMERATOR_DENOMINATOR));
        let whitelist = vector::empty<address>();
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
            token_mutate_setting,
            whitelist
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
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let (whitelist_add, whitelist_cap) = account::create_resource_account(account, seeds);
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
        
        let baseuri = candy_data.baseuri;
        let candy =candy_data.minted;

        let properties = vector::empty<String>();
        string::append(&mut baseuri,num_str(candy));
        
        let token_name = candy_data.collection_name;
        string::append(&mut token_name,string::utf8(b" #"));
        string::append(&mut token_name,num_str(candy));
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
        token::create_token_script(
            &resource_signer_from_cap,
            candy_data.collection_name,
            token_name,
            candy_data.collection_description,
            1,
            0,
            baseuri,
            candy_data.royalty_payee_address,
            candy_data.royalty_points_denominator,
            candy_data.royalty_points_numerator,
            candy_data.token_mutate_setting,
            properties,
            vector<vector<u8>>[],
            properties
        );
        let token_data_id = token::create_token_data_id(candymachine,candy_data.collection_name,token_name);
        token::opt_in_direct_transfer(receiver,true);
        coin::transfer<0x1::aptos_coin::AptosCoin>(receiver, resource_data.source, mint_price);
        token::mint_token_to(&resource_signer_from_cap,receiver_addr,token_data_id,1);
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
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        token::mutate_one_token(&resource_signer_from_cap,token_owner,token_id,keys,values,types);
    }
    public fun mutate_tokendata_uri(
        account: &signer,
        token_data_id: TokenDataId,
        uri: String,
        candymachine: address,
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
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
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        token::mutate_tokendata_property(&resource_signer_from_cap,token_data_id,keys,values,types);  
    }
    fun num_str(num: u64): String{
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
}
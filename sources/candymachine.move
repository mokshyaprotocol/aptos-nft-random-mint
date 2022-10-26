module candymachine::candymachine{
    use std::signer;
    use std::string::{String};
    use std::vector;
    use std::error;
    use aptos_framework::coin::{Self};
    use aptos_framework::account;
    use aptos_token::token::{Self};
    use aptos_std::simple_map::{Self, SimpleMap};

    const INVALID_SIGNER: u64 = 0;
    const INVALID_amount: u64 = 1;
    const CANNOT_ZERO: u64 = 2;
    const EINVALID_ROYALTY_NUMERATOR_DENOMINATOR: u64 = 3;

    struct CandyMachine has key {
        mint_price: u64,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        presale_mint_time: u64,
        public_sale_mint_time: u64,
        presale_mint_price: u64,
        public_sale_mint_price: u64,
        paused: bool,
        whitelist: vector<address>,
    }
    struct Whitelist has key {
        whitelist: vector<address>,
    }
    struct ResourceInfo has key {
            source: address,
            resource_cap: account::SignerCapability
    }
    public entry fun set_up_candy(
        account: &signer,
        mint_price: u64,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        presale_mint_time: u64,
        public_sale_mint_price: u64,
        presale_mint_price: u64,
        public_sale_mint_time: u64,
        resource_account: address
    )acquires ResourceInfo{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(resource_account);
        assert!(royalty_points_denominator > 0, error::invalid_argument(EINVALID_ROYALTY_NUMERATOR_DENOMINATOR));
        assert!(royalty_points_numerator <= royalty_points_denominator, error::invalid_argument(EINVALID_ROYALTY_NUMERATOR_DENOMINATOR));
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let whitelist = vector::empty<address>();
        move_to<CandyMachine>(&resource_signer_from_cap, CandyMachine{
            mint_price,
            royalty_points_denominator,
            royalty_points_numerator,
            presale_mint_time,
            public_sale_mint_time,
            public_sale_mint_price,
            presale_mint_price,
            paused:false,
            whitelist
            }
        );
    }
    public entry fun create_collection(
        account: &signer,
        name: String,
        description: String,
        uri: String,
        maximum: u64,
        mutate_setting: vector<bool>,
        seeds: vector<u8>
    ) {
        let (_resource, resource_cap) = account::create_resource_account(account, seeds);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_cap);
        token::create_collection(&resource_signer_from_cap, name, description, uri, maximum, mutate_setting);
        move_to<ResourceInfo>(&resource_signer_from_cap, ResourceInfo{resource_cap: resource_cap, source: signer::address_of(account)});
    }
    public entry fun create_token_script(
        account: &signer,
        collection: String,
        name: String,
        description: String,
        balance: u64,
        maximum: u64,
        uri: String,
        royalty_payee_address: address,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        mutate_setting: vector<bool>,
        property_keys: vector<String>,
        property_values: vector<vector<u8>>,
        property_types: vector<String>,
        resource_account: address
    )acquires ResourceInfo{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(resource_account); 
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        token::create_collection(&resource_signer_from_cap, name, description, uri, maximum, mutate_setting);
        token::create_token_script(
            &resource_signer_from_cap,
            collection,
            name,
            description,
            balance,
            maximum,
            uri,
            royalty_payee_address,
            royalty_points_denominator,
            royalty_points_numerator,
            mutate_setting,
            property_keys,
            property_values,
            property_types
        )
    }
    public entry fun create_whitelist(
        account: &signer,
        candymachine: address,
        whitelist: vector<address>,
        seeds:vector<u8>
    )acquires ResourceInfo{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        
        let (whitelist_add, whitelist_cap) = account::create_resource_account(account, seeds);
        let whitelist_signer_from_cap = account::create_signer_with_capability(&whitelist_cap);
        move_to<Whitelist>(&whitelist_signer_from_cap, Whitelist{whitelist});
    }
    public entry fun mint_script(
        receiver: &signer,
        candymachine: address,
        amount: u64,
        collection: String,
        name: String,
    )acquires ResourceInfo, CandyMachine{
        let receiver_addr = signer::address_of(receiver);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        let candy_data = borrow_global<CandyMachine>(candymachine);
        assert!(candy_data.paused == false, INVALID_SIGNER);
        // assert!(amount > 0, error::invalid_argument(CANNOT_ZERO));
        let now = aptos_framework::timestamp::now_seconds();
        if (now > candy_data.presale_mint_time){
            if (now > candy_data.public_sale_mint_time){
                coin::transfer<0x1::aptos_coin::AptosCoin>(receiver, resource_data.source, candy_data.public_sale_mint_price);
            }
            else {
                coin::transfer<0x1::aptos_coin::AptosCoin>(receiver, resource_data.source, candy_data.presale_mint_price);
            };
        };
        let token_data_id = token::create_token_data_id(candymachine,collection,name);
        token::opt_in_direct_transfer(receiver,true);
        token::mint_token_to(&resource_signer_from_cap,receiver_addr,token_data_id,amount)
    }
    public fun pause_mint(
        account: &signer,
        candymachine: address,
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        candy_data.paused = false;
    }
    public fun resume_mint(
        account: &signer,
        candymachine: address,
    )acquires ResourceInfo,CandyMachine{
        let account_addr = signer::address_of(account);
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        assert!(resource_data.source == account_addr, INVALID_SIGNER);
        let candy_data = borrow_global_mut<CandyMachine>(candymachine);
        candy_data.paused = true;
    }
    public fun update_candy(
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
}
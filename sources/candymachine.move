module candymachine::candymachine{
    use std::signer;
    use std::string::{Self, String};
    use std::vector;
    // use aptos_framework::coin::{Self};
    use aptos_framework::account;
    use aptos_token::token::{Self};

    struct CandyMachine has key {
        mint_price: u64,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        presale_mint_time: u64,
        public_sale_mint_time: u64,
    }
    struct ResourceInfo has key {
            source: address,
            resource_cap: account::SignerCapability
    }
    public fun set_up_candy(
        account: &signer,
        mint_price: u64,
        royalty_points_denominator: u64,
        royalty_points_numerator: u64,
        presale_mint_time: u64,
        public_sale_mint_time: u64,
        resource_account: address
    )acquires ResourceInfo{
        let resource_data = borrow_global<ResourceInfo>(resource_account);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        move_to<CandyMachine>(&resource_signer_from_cap, CandyMachine{mint_price,royalty_points_denominator,royalty_points_numerator,presale_mint_time,public_sale_mint_time});
    }
    public fun create_collection(
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
    public fun create_token_script(
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
        let resource_data = borrow_global<ResourceInfo>(resource_account); 
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
    public fun mint_script(
        receiver: &signer,
        candymachine: address,
        amount
    ){
        let resource_data = borrow_global<ResourceInfo>(candymachine);
        let resource_signer_from_cap = account::create_signer_with_capability(&resource_data.resource_cap);
        token::mint_script(&resource_signer_from_cap,candymachine,collection,name,amount)
    }
}
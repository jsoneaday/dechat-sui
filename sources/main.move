#[allow(unused_use, unused_field)]
module dechat_sui::main {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use std::string::{Self, String, utf8};
    use std::option::Option;
    use dechat_sui::profile;
    use dechat_sui::post;
    use dechat_sui::post::{Post, get_post_id, get_new_post};
    use dechat_sui::utils::{get_supporting_chain};
    use dechat_sui::like;
    
    struct MAIN has drop {}

    struct DechatAdmin has key {
        id: UID
    }

    struct AppMetadata has key {
        id: UID,
        timestamp: u64,
        version: String
    }
      
    fun init(main: MAIN, ctx: &mut TxContext) {
        assert!(sui::types::is_one_time_witness(&main), 1);
        // todo: needs code to make sure only certain addresses can init
        let admin = DechatAdmin {
            id: object::new(ctx)
        };        
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    /// admin is passed but not checked since it could only have been passed in by original caller of init
    entry fun create_app_metadata(clock: &Clock, version: String, _admin: &DechatAdmin, ctx: &mut TxContext) {
        let app_metadata = AppMetadata {
            id: object::new(ctx),
            timestamp: clock::timestamp_ms(clock),
            version
        };
        
        transfer::share_object(app_metadata);
    }

    entry fun create_profile(        
        user_name: String,
        full_name: String,
        description: Option<String>,
        ctx: &mut TxContext
    ) {
        profile::create_profile(user_name, full_name, description, ctx);       
    }
 
    entry fun create_post(
        clock: &Clock,
        message: String, 
        ctx: &mut TxContext
    ) {
        post::create_post(clock, message, ctx);
    }

    entry fun create_like(
        clock: &Clock,
        post: &Post,
        ctx: &mut TxContext
    ) {
        like::create_like(clock, post, ctx);
    }

    entry fun create_ext_like(
        clock: &Clock,
        chain: String,
        post_id: String,
        ctx: &mut TxContext
    ) {
        like::create_ext_like(clock, chain, post_id, ctx);
    }

    entry fun create_dislike(
        clock: &Clock,
        post: &Post,
        ctx: &mut TxContext
    ) {
        like::create_dislike(clock, post, ctx);
    }

    entry fun create_ext_dislike(
        clock: &Clock,
        chain: String,
        post_id: String,
        ctx: &mut TxContext
    ) {
        like::create_ext_dislike(clock, chain, post_id, ctx);
    }

    entry fun create_response_post(
        clock: &Clock, 
        post: &Post,
        message: String,
        ctx: &mut TxContext
    ) {
        post::create_response_post(clock, post, message, ctx);
    }

    entry fun create_ext_response_post(
        clock: &Clock,
        message: String,
        respondee_post_id: String,
        chain: String,
        ctx: &mut TxContext
    ) {
        post::create_ext_response_post(clock, message, respondee_post_id, chain, ctx);
    }

    /// @chain should be one of the chain constants listed at top of contract
    entry fun create_share_post(
        clock: &Clock, 
        post: &Post,
        message: Option<String>,
        ctx: &mut TxContext
    ) {
        post::create_share_post(clock, post, message, ctx);
    }

    entry fun create_ext_share_post(
        clock: &Clock,
        message: Option<String>,
        sharee_post_id: String,
        chain: String,
        ctx: &mut TxContext
    ) {
        post::create_ext_share_post(clock, message, sharee_post_id, chain, ctx);
    }    
    
    #[test]
    fun test_init() {        
        use sui::test_scenario;
        use sui::test_scenario::{ Self as test, next_tx};

        let admin_addr = @0xBABE;

        let original_scenario = test_scenario::begin(admin_addr);
        let scenario = &mut original_scenario;
        {
            init(MAIN{}, test_scenario::ctx(scenario));
        };

        next_tx(scenario, admin_addr);
        {
            let admin = test::take_from_address<DechatAdmin>(scenario, admin_addr);
            test::return_to_address<DechatAdmin>(admin_addr, admin);
        };
        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_create_app_metadata() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test};
        use sui::test_utils::assert_eq;

        let admin_address = @0xBABE;
        let version = utf8(b"0.0.1");

        let original_scenario = test_scenario::begin(admin_address);
        let scenario = &mut original_scenario;
        {
            init(MAIN{}, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin_address);
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let admin = DechatAdmin { id: object::new(ctx) };

            create_app_metadata(
                &clock,
                version,
                &admin,
                ctx
            );            

            clock::destroy_for_testing(clock);
            transfer::transfer(admin, admin_address);            
        };

        test_scenario::next_tx(scenario, admin_address);
        {
            let app_metadata = test::take_shared<AppMetadata>(scenario);
            assert_eq(app_metadata.version, version);
            test::return_shared(app_metadata);
        };

        test_scenario::end(original_scenario);
    }
}
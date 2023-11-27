#[allow(unused_use, unused_field)]
module dechat_sui::main {
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use std::string::{Self, String, utf8};
    use std::option::Option;
    use dechat_sui::profile;
    use dechat_sui::post;
    use dechat_sui::post::{Post, get_post_id, get_new_post};
    use dechat_sui::utils::{get_supporting_chain, ExternalChain};
    
    struct MAIN has drop {}

    struct DechatAdmin has key {
        id: UID
    }

    struct AppMetadata has key {
        id: UID,
        timestamp: u64,
        version: String
    }
   
    struct Categorization has key, store {
        id: UID,
        post_id: Option<ID>,
        ext_post_id: Option<String>,
        normal: bool,        
        lie: bool,
        misleading: bool,        
        nudity: bool,
        sexual_content: bool,
        violence: bool,
        otherwise_offensive: bool,
    }

    /// likes on sui chain
    struct Like has key, store {
        id: UID,
        timestamp: u64,
        liker: address,
        post_id: ID
    }

    /// dislikes on sui chain
    struct DisLike has key, store {
        id: UID,
        timestamp: u64,
        disliker: address,
        post_id: ID
    }

    /// likes on foreign chain
    /// liker can be id or address
    /// target asset or address being liked
    struct ExtLike has key, store {
        id: UID,
        timestamp: u64,
        chain: ExternalChain,
        liker: address,
        post_id: String
    }

    struct ExtDisLike has key, store {
        id: UID,
        timestamp: u64,
        chain: ExternalChain,
        disliker: address,
        post_id: String
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
        let like = Like {
            id: object::new(ctx),
            timestamp: clock::timestamp_ms(clock),
            liker: tx_context::sender(ctx),
            post_id: get_post_id(post)
        };

        transfer::share_object(like);
    }

    entry fun create_ext_like(
        clock: &Clock,
        chain: String,
        post_id: String,
        ctx: &mut TxContext
    ) {
        let ext_like = ExtLike {
            id: object::new(ctx),
            timestamp: clock::timestamp_ms(clock),
            chain: get_supporting_chain(chain),
            liker: tx_context::sender(ctx),
            post_id
        };

        transfer::share_object(ext_like);
    }

    entry fun create_dislike(
        clock: &Clock,
        post: &Post,
        ctx: &mut TxContext
    ) {
        let dislike = DisLike {
            id: object::new(ctx),
            timestamp: clock::timestamp_ms(clock),
            disliker: tx_context::sender(ctx),
            post_id: get_post_id(post)
        };

        transfer::share_object(dislike);
    }

    entry fun create_ext_dislike(
        clock: &Clock,
        chain: String,
        post_id: String,
        ctx: &mut TxContext
    ) {
        let ext_dislike = ExtDisLike {
            id: object::new(ctx),
            timestamp: clock::timestamp_ms(clock),
            chain: get_supporting_chain(chain),
            disliker: tx_context::sender(ctx),
            post_id
        };

        transfer::share_object(ext_dislike);
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

    #[test]
    fun test_create_like() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;

        let profile_owner_address = @0xCAFE;

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = utf8(b"hello world");
            let post = get_new_post(profile_owner_address, clock::timestamp_ms(&clock), message, ctx);
                        
            create_like(&clock, &post, ctx);

            clock::destroy_for_testing(clock);
            transfer::public_transfer(post, profile_owner_address);
        };

        next_tx(scenario, profile_owner_address);
        {
            let like = test::take_shared<Like>(scenario);
            
            assert_eq(like.liker, profile_owner_address);

            test::return_shared(like);
        };

        end(original_scenario);
    }

    #[test]
    fun test_create_dislike() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;

        let profile_owner_address = @0xCAFE;

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = utf8(b"hello world");
            let post = get_new_post(profile_owner_address, clock::timestamp_ms(&clock), message, ctx);
                        
            create_dislike(&clock, &post, ctx);

            clock::destroy_for_testing(clock);
            transfer::public_transfer(post, profile_owner_address);
        };

        next_tx(scenario, profile_owner_address);
        {
            let dislike = test::take_shared<DisLike>(scenario);
            
            assert_eq(dislike.disliker, profile_owner_address);

            test::return_shared(dislike);
        };

        end(original_scenario);
    }     

    #[test]
    fun test_create_ext_like() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;

        let profile_owner_address = @0xCAFE;

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
                                    
            create_ext_like(
                &clock,
                utf8(b"aptos"),
                utf8(b"post_id123"),
                ctx
            );

            clock::destroy_for_testing(clock);
        };

        next_tx(scenario, profile_owner_address);
        {
            let ext_like = test::take_shared<ExtLike>(scenario);
            
            assert_eq(ext_like.liker, profile_owner_address);

            test::return_shared(ext_like);
        };

        end(original_scenario);
    }

    #[test]
    fun test_create_ext_dislike() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;

        let profile_owner_address = @0xCAFE;

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
                                    
            create_ext_dislike(
                &clock,
                utf8(b"aptos"),
                utf8(b"post_id123"),
                ctx
            );

            clock::destroy_for_testing(clock);
        };

        next_tx(scenario, profile_owner_address);
        {
            let ext_dislike = test::take_shared<ExtDisLike>(scenario);
            
            assert_eq(ext_dislike.disliker, profile_owner_address);

            test::return_shared(ext_dislike);
        };

        end(original_scenario);
    }    
}
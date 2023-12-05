#[allow(unused_use)]
module dechat_sui::post {
    use sui::object::{Self, UID, ID};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::tx_context;
    use sui::tx_context::TxContext;
    use dechat_sui::utils::{get_supporting_chain, get_new_categorization, ExternalChain, Categorization};
    use std::string::{String, utf8};    
    use std::option::Option;

    friend dechat_sui::main;
    friend dechat_sui::like; 

    struct Post has key {
        id: UID,
        owner: address,
        timestamp: u64,
        message: String,
        categorization: Categorization
    }

    /// On-chain response post object
    struct ResponsePost has key {
        id: UID,
        owner: address,
        timestamp: u64,
        message: String,
        respondee_post_id: ID,
        categorization: Categorization
    }

    /// Post that responds to a post on an external chain
    /// owner stringified external address
    /// responding_msg_id stringified external data id or address
    struct ExtResponsePost has key {
        id: UID,
        owner: address,
        timestamp: u64,
        message: String,
        chain: ExternalChain,
        respondee_post_id: String,
        categorization: Categorization
    }
    
    /// On-chain post sharing object
    struct SharePost has key {
        id: UID,
        owner: address,
        timestamp: u64,
        message: Option<String>,
        sharee_post_id: ID,
        categorization: Categorization
    }

    /// Share Post to external foreign chain Posts
    /// owner stringified external address
    /// sharing_msg_id stringified external data id or address
    struct ExtSharePost has key {
        id: UID,
        owner: address,
        timestamp: u64,
        message: Option<String>,
        chain: ExternalChain,
        sharee_post_id: String,
        categorization: Categorization
    }

    public(friend) fun get_post_id(post: &Post): ID {
        object::uid_to_inner(&post.id)
    }

    public(friend) fun get_post_message(post: &Post): String {
        post.message
    }

    public(friend) fun get_response_post_message(response_post: &ResponsePost): String {
        response_post.message
    }

    public(friend) fun get_ext_response_post_message(ext_response_post: &ExtResponsePost): String {
        ext_response_post.message
    }

    public(friend) fun get_share_post_message(share_post: &SharePost): Option<String> {
        share_post.message
    }

    public(friend) fun get_ext_share_post_message(ext_share_post: &ExtSharePost): Option<String> {
        ext_share_post.message
    }

    public(friend) fun create_post(
        clock: &Clock,
        message: String,
        ctx: &mut TxContext
    ) {
        let post = Post {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            categorization: get_new_categorization()
        };

        transfer::share_object(post);
    }

    public(friend) fun create_response_post(
        clock: &Clock, 
        post: &Post,
        message: String,
        ctx: &mut TxContext
    ) {
        let response_post = ResponsePost {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            respondee_post_id: object::uid_to_inner(&post.id),
            categorization: get_new_categorization()
        };

        transfer::share_object(response_post);
    }

    public(friend) fun create_ext_response_post(
        clock: &Clock,
        message: String,
        respondee_post_id: String,
        chain: String,
        ctx: &mut TxContext
    ) {
        let response_post = ExtResponsePost {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            chain: get_supporting_chain(chain),
            respondee_post_id,
            categorization: get_new_categorization()
        };

        transfer::share_object(response_post);
    }

    /// @chain should be one of the chain constants listed at top of contract
    public(friend) fun create_share_post(
        clock: &Clock, 
        post: &Post,
        message: Option<String>,
        ctx: &mut TxContext
    ) {
        let share_post = SharePost {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            sharee_post_id: object::uid_to_inner(&post.id),
            categorization: get_new_categorization()
        };

        transfer::share_object(share_post);
    }

    public(friend) fun create_ext_share_post(
        clock: &Clock,
        message: Option<String>,
        sharee_post_id: String,
        chain: String,
        ctx: &mut TxContext
    ) {
        let share_post = ExtSharePost {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            chain: get_supporting_chain(chain),
            sharee_post_id,
            categorization: get_new_categorization()
        };

        transfer::share_object(share_post);
    }

    #[test]
    fun test_create_post() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;

        let profile_owner_address = @0xCAFE;

        let post_message = utf8(b"hello world");

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            
            create_post(&clock, post_message, ctx);

            clock::destroy_for_testing(clock);
        };

        next_tx(scenario, profile_owner_address);
        {
            let post = test::take_shared<Post>(scenario);
            assert_eq(get_post_message(&post), post_message);

            test::return_shared(post);
        };

        end(original_scenario);
    }

    #[test]
    fun test_create_response_post() {
        use sui::test_scenario;
        use sui::test_scenario::{next_tx, Self as test};
        use sui::test_utils::assert_eq;

        let profile_owner_address = @0xCAFE;

        let message = utf8(b"hello world");

        let original_scenario = test_scenario::begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);  

            create_post(&clock, utf8(b"hello world in post"), ctx);          

            clock::destroy_for_testing(clock);
        };

        next_tx(scenario, profile_owner_address);
        {
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));
            let post = test::take_shared<Post>(scenario);           

            create_response_post(&clock, &post, message, test_scenario::ctx(scenario));

            clock::destroy_for_testing(clock);
            test::return_shared(post);
        };

        next_tx(scenario, profile_owner_address);
        {
            let response_post = test::take_shared<ResponsePost>(scenario);

            assert_eq(get_response_post_message(&response_post), message);

            test::return_shared(response_post);
        };
      
        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_create_ext_response_post() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test, next_tx};
        use sui::test_utils::assert_eq;

        let profile_owner_address = @0xCAFE;

        let message = utf8(b"hello world");

        let original_scenario = test_scenario::begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
                        
            create_ext_response_post(
                &clock,
                message, 
                utf8(b"123"),
                utf8(b"aptos"),
                ctx
            );

            clock::destroy_for_testing(clock);
        };

        next_tx(scenario, profile_owner_address);
        {
            let ext_response_post = test::take_shared<ExtResponsePost>(scenario);
            assert_eq(get_ext_response_post_message(&ext_response_post), message);

            test::return_shared(ext_response_post);
        };

        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_create_share_post() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test, next_tx};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;

        let message = utf8(b"hello world");          

        let original_scenario = test_scenario::begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {       
            let ctx = test_scenario::ctx(scenario);                      
            let clock = clock::create_for_testing(ctx);
            
            create_post(&clock, message, ctx);
                        
            clock::destroy_for_testing(clock);    
        };

        next_tx(scenario, profile_owner_address);
        {
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));
            let post = test::take_shared<Post>(scenario);

            create_share_post(&clock, &post, option::some(message), test_scenario::ctx(scenario));            
            
            clock::destroy_for_testing(clock);   
            test::return_shared(post);
        };

        next_tx(scenario, profile_owner_address);
        {
            let share_post = test::take_shared<SharePost>(scenario);
            assert_eq(get_share_post_message(&share_post), option::some(message));

            test::return_shared(share_post);
        };        
        
        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_create_ext_share_post() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test, next_tx};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;

        let message = option::some(utf8(b"hello world"));

        let original_scenario = test_scenario::begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);
                        
            create_ext_share_post(
                &clock,
                message, 
                utf8(b"123"),
                utf8(b"aptos"),
                ctx
            );

            clock::destroy_for_testing(clock);
        };

        next_tx(scenario, profile_owner_address);
        {
            let ext_share_post = test::take_shared<ExtSharePost>(scenario);

            assert_eq(get_ext_share_post_message(&ext_share_post), message);

            test::return_shared(ext_share_post);
        };

        test_scenario::end(original_scenario);
    }
}
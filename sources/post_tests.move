#[test_only]
module dechat_sui::post_tests {    
    use sui::clock;
    use std::string::utf8;
    use dechat_sui::post::{
        Post, 
        ResponsePost, 
        ExtResponsePost,
        SharePost,
        ExtSharePost,
        create_post, 
        create_response_post, 
        create_ext_response_post,
        create_share_post,
        create_ext_share_post,
        get_post_message,
        get_response_post_message,
        get_ext_response_post_message,
        get_share_post_message,
        get_ext_share_post_message
    };

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
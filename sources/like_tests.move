#[test_only]
module dechat_sui::like_tests {
    use sui::clock;
    use sui::transfer;
    use dechat_sui::post::{get_new_post};
    use dechat_sui::like::{Like, DisLike, ExtLike, ExtDisLike, create_like, create_dislike, create_ext_like, create_ext_dislike};
    use std::string::utf8;


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
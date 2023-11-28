#[allow(unused_use)]
module dechat_sui::like {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use dechat_sui::post::{get_post_id, get_new_post, Post};
    use dechat_sui::utils::{get_supporting_chain, ExternalChain};
    use std::string::{utf8, String};
    
    friend dechat_sui::main;

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

    public(friend) fun get_like_liker(like: &Like): address {
        like.liker
    }

    public(friend) fun get_dislike_disliker(dislike: &DisLike): address {
        dislike.disliker
    }

    public(friend) fun get_ext_like_liker(ext_like: &ExtLike): address {
        ext_like.liker
    }

    public(friend) fun get_ext_dislike_disliker(ext_dislike: &ExtDisLike): address {
        ext_dislike.disliker
    }

    public(friend) fun create_like(
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

    public(friend) fun create_ext_like(
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

    public(friend) fun create_dislike(
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

    public(friend) fun create_ext_dislike(
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
            
            assert_eq(get_like_liker(&like), profile_owner_address);

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
            
            assert_eq(get_dislike_disliker(&dislike), profile_owner_address);

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
            
            assert_eq(get_ext_like_liker(&ext_like), profile_owner_address);

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
            
            assert_eq(get_ext_dislike_disliker(&ext_dislike), profile_owner_address);

            test::return_shared(ext_dislike);
        };

        end(original_scenario);
    }
}
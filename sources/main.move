#[allow(unused_use, unused_field)]
module dechat_sui::main {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::dynamic_object_field as ofield;
    use sui::object_table;
    use sui::object_table::ObjectTable;
    use sui::clock::{Self, Clock};    
    use std::string::{Self, String};
    use std::option;
    use std::vector;
    use std::option::Option;

    struct DechatAdmin has key {
        id: UID
    }

    struct AppMetadata has key {
        id: UID,
        timestamp: u64,
        version: String
    }

    struct Profile has key, store {
        id: UID,
        address: address,
        user_name: String,
        full_name: String,
        description: Option<String>
    }

    struct Post has key, store {
        id: UID,
        timestamp: u64,
        message: String,
        response_posts: ObjectTable<u64, ResponsePost>,
        share_posts: ObjectTable<u64, SharePost>
    }

    struct ResponsePost has key, store {
        id: UID,
        timestamp: u64,
        message: String
    }
    
    struct SharePost has key, store {
        id: UID,
        timestamp: u64,
        message: Option<String>
    }

    struct AllPosts has key, store {
        id: UID,
        posts: ObjectTable<u64, Post>
    }

    fun init(ctx: &mut TxContext) {
        // todo: needs code to make sure only certain addresses can init
        let admin = DechatAdmin {
            id: object::new(ctx)
        };        
        transfer::transfer(admin, tx_context::sender(ctx));

        let all_posts = AllPosts {
            id: object::new(ctx),
            posts: object_table::new<u64, Post>(ctx)
        };
        transfer::share_object(all_posts);
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
        let address = tx_context::sender(ctx);

        let profile = Profile {
            id: object::new(ctx),
            address,
            user_name,
            full_name,
            description
        };

        transfer::share_object(profile);
    }
 
    entry fun add_post_to_all_posts(clock: &Clock, all_posts: &mut AllPosts, profile: &Profile, message: String, ctx: &mut TxContext) {
        let timestamp = clock::timestamp_ms(clock);
        let address = tx_context::sender(ctx);
        assert!(address == profile.address, 1);

        let post = Post {
            id: object::new(ctx),
            timestamp,
            message,
            response_posts: object_table::new<u64, ResponsePost>(ctx),
            share_posts: object_table::new<u64, SharePost>(ctx)
        };

        let posts_length = object_table::length(&all_posts.posts) + 1;
        object_table::add(&mut all_posts.posts, posts_length, post);
    }

    entry fun add_response_post_to_all_posts(clock: &Clock, all_posts: &mut AllPosts, profile: &Profile, parent_post_index: u64, message: String, ctx: &mut TxContext) {
        assert!(parent_post_index > 0, 1); // cannot be 0 since this is a response to a post
        let address = tx_context::sender(ctx);
        assert!(address == profile.address, 1);

        let post = object_table::borrow_mut<u64, Post>(&mut all_posts.posts, parent_post_index);

        let response_post = ResponsePost {
            id: object::new(ctx),
            timestamp: clock::timestamp_ms(clock),
            message
        };

        let response_posts_length = object_table::length(&post.response_posts);
        object_table::add<u64, ResponsePost>(&mut post.response_posts, response_posts_length + 1, response_post);
    }

    entry fun add_share_post_to_all_posts(clock: &Clock, all_posts: &mut AllPosts, profile: &Profile, parent_post_index: u64, message: Option<String>, ctx: &mut TxContext) {
        assert!(parent_post_index > 0, 1); // cannot be 0 since this is a share to a post
        let address = tx_context::sender(ctx);
        assert!(address == profile.address, 1);

        let post = object_table::borrow_mut<u64, Post>(&mut all_posts.posts, parent_post_index);

        let share_post = SharePost {
            id: object::new(ctx),
            timestamp: clock::timestamp_ms(clock),
            message
        };

        let share_posts_length = object_table::length(&post.share_posts);
        object_table::add<u64, SharePost>(&mut post.share_posts, share_posts_length + 1, share_post);
    }
    
    #[test]
    fun test_init() {        
        let ctx = tx_context::dummy();

        init(&mut ctx);
    }

    #[test]
    fun test_create_app_metadata() {
        use sui::test_scenario;

        let admin_address = @0xBABE;

        let original_scenario = test_scenario::begin(admin_address);
        let scenario = &mut original_scenario;
        {
            init(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin_address);
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);
            let version = std::string::utf8(b"0.0.1");
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

        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_create_profile() {
        use sui::test_scenario;
        use std::option;

        let admin = @0xBABE;
        let profile_owner = @0xCAFE;

        let original_scenario = test_scenario::begin(admin);
        let scenario = &mut original_scenario;
        {
            init(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, profile_owner);
        {
            let user_name = std::string::utf8(b"dave");
            let full_name = std::string::utf8(b"David Choi");
            create_profile(user_name, full_name, option::none(), test_scenario::ctx(scenario))
        };

        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_add_post_to_all_posts() {
        use sui::test_scenario;
        use std::option;

        let admin_address = @0xBABE;
        let profile_owner_address = @0xCAFE;

        let user_name = std::string::utf8(b"dave");
        let full_name = std::string::utf8(b"David Choi");

        let original_scenario = test_scenario::begin(admin_address);
        let scenario = &mut original_scenario;
        {
            init(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, profile_owner_address);
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = std::string::utf8(b"");
            let profile = Profile {
                id: object::new(ctx),
                address: profile_owner_address,
                user_name,
                full_name,
                description: option::none()
            };
            let all_posts = AllPosts {
                id: object::new(ctx),
                posts: object_table::new<u64, Post>(ctx)
            };
                        
            add_post_to_all_posts(&clock, &mut all_posts, &profile, message, ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_posts);
        };

        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_add_response_post_to_all_posts() {
        use sui::test_scenario;
        use std::option;

        let admin_address = @0xBABE;
        let profile_owner_address = @0xCAFE;

        let user_name = std::string::utf8(b"dave");
        let full_name = std::string::utf8(b"David Choi");

        let original_scenario = test_scenario::begin(admin_address);
        let scenario = &mut original_scenario;
        {
            init(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, profile_owner_address);
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = std::string::utf8(b"");
            let profile = Profile {
                id: object::new(ctx),
                address: profile_owner_address,
                user_name,
                full_name,
                description: option::none()
            };
            let all_posts = AllPosts {
                id: object::new(ctx),
                posts: object_table::new<u64, Post>(ctx)
            };
            let post_index = 1;
            object_table::add(
                &mut all_posts.posts, 
                post_index, 
                Post {
                    id: object::new(ctx),
                    timestamp: clock::timestamp_ms(&clock),
                    message,
                    response_posts: object_table::new<u64, ResponsePost>(ctx),
                    share_posts: object_table::new<u64, SharePost>(ctx)
                }
            );
                        
            add_response_post_to_all_posts(&clock, &mut all_posts, &profile, post_index, message, ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_posts);
        };

        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_add_share_post_to_all_posts() {
        use sui::test_scenario;
        use std::option;

        let admin_address = @0xBABE;
        let profile_owner_address = @0xCAFE;

        let user_name = std::string::utf8(b"dave");
        let full_name = std::string::utf8(b"David Choi");

        let original_scenario = test_scenario::begin(admin_address);
        let scenario = &mut original_scenario;
        {
            init(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, profile_owner_address);
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = std::string::utf8(b"");
            let profile = Profile {
                id: object::new(ctx),
                address: profile_owner_address,
                user_name,
                full_name,
                description: option::none()
            };
            let all_posts = AllPosts {
                id: object::new(ctx),
                posts: object_table::new<u64, Post>(ctx)
            };
            let post_index = 1;
            object_table::add(
                &mut all_posts.posts, 
                post_index, 
                Post {
                    id: object::new(ctx),
                    timestamp: clock::timestamp_ms(&clock),
                    message,
                    response_posts: object_table::new<u64, ResponsePost>(ctx),
                    share_posts: object_table::new<u64, SharePost>(ctx)
                }
            );
                        
            add_share_post_to_all_posts(&clock, &mut all_posts, &profile, post_index, option::some(message), ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_posts);
        };

        test_scenario::end(original_scenario);
    }
}
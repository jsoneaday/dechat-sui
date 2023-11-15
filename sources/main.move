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
        user_name: String,
        message: String
    }

    struct RespondedPost has key, store {
        id: UID,
        timestamp: u64,
        user_name: String,
        responded_msg_id: UID,
        message: String
    }
    
    struct SharedPost has key, store {
        id: UID,
        timestamp: u64,
        user_name: String,
        shared_msg_id: UID,
        message: String
    }

    fun init(ctx: &mut TxContext) {
        let admin = DechatAdmin {
            id: object::new(ctx)
        };
        
        transfer::transfer(admin, tx_context::sender(ctx));        
    }

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

        let posts = object_table::new<String, Post>(ctx);
        let responded_posts = object_table::new<String, RespondedPost>(ctx);
        let shared_posts = object_table::new<String, SharedPost>(ctx);
        
        ofield::add(&mut profile.id, b"posts", posts);
        ofield::add(&mut profile.id, b"responded_posts", responded_posts);
        ofield::add(&mut profile.id, b"shared_posts", shared_posts);

        transfer::share_object(profile);
    }
 
    fun add_post(
        clock: &Clock, 
        post_table: &mut ObjectTable<String, Post>, 
        post: Post
    ) {
        let _ts = clock::timestamp_ms(clock);
        
        object_table::add(post_table, post.user_name, post);
    }

    entry fun add_post_to_profile(clock: &Clock, profile: &mut Profile, timestamp: u64, user_name: String, message: String, ctx: &mut TxContext) {
        let address = tx_context::sender(ctx);
        assert!(address == profile.address, 1);

        let post_table = ofield::borrow_mut<vector<u8>, ObjectTable<String, Post>>(
            &mut profile.id, 
            b"posts"
        );

        let post = Post {
            id: object::new(ctx),
            timestamp,
            user_name,
            message
        };

        add_post(clock, post_table, post);
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
    fun test_add_post_to_profile() {
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
            
            let posts = object_table::new<String, Post>(ctx);        
            ofield::add(&mut profile.id, b"posts", posts);
            
            add_post_to_profile(&clock, &mut profile, clock::timestamp_ms(&clock), user_name, message, ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
        };

        test_scenario::end(original_scenario);
    }
}
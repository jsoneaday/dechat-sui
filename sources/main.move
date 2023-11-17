#[allow(unused_use, unused_field)]
module dechat_sui::main {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object_table;
    use sui::object_table::ObjectTable;
    use sui::clock::{Self, Clock};    
    use sui::hex::encode;
    use std::string::{Self, String, utf8};
    use std::option;
    use std::vector;
    use std::option::Option;
    use std::debug;

    struct MAIN has drop {}

    struct DechatAdmin has key {
        id: UID
    }

    struct AppMetadata has key {
        id: UID,
        timestamp: u64,
        version: String
    }

    const SUI: vector<u8> = b"sui";
    const APTOS: vector<u8> = b"aptos";
    const COSMOS: vector<u8> = b"cosmos";
    #[allow(unused)]
    const ARWEAVE: vector<u8> = b"arweave";

    struct SupportingChain has store {
        sui: bool,
        aptos: bool,
        cosmos: bool,
        arweave: bool
    }

    struct Profile has key, store {
        id: UID,
        address: address,
        user_name: String,
        full_name: String,
        description: Option<String>
    }

    /// u64 key represents an index value
    /// @chain_agnos_uid is for other chains to be able to identify this post,
    /// it is the stringified UID of the post
    struct Post has key, store {
        id: UID,
        timestamp: u64,
        message: String,
        chain_agnos_uid: String
    }

    /// @chain the chain containing the post I am responding to
    /// @responding_msg_id the stringified version of the post id
    struct ResponsePost has key, store {
        id: UID,
        timestamp: u64,
        message: String,
        chain: SupportingChain,
        responding_msg_id: String
    }
    
    /// @chain the chain containing the post I am responding to
    /// @sharing_msg_id the stringified version of the post id
    struct SharePost has key, store {
        id: UID,
        timestamp: u64,
        message: Option<String>,
        chain: SupportingChain,
        sharing_msg_id: String
    }

    /// u64 key represents an index value
    struct AllPosts has key, store {
        id: UID,
        posts: ObjectTable<u64, Post>,
        response_posts: ObjectTable<u64, ResponsePost>,
        share_posts: ObjectTable<u64, SharePost>
    }

    fun init(main: MAIN, ctx: &mut TxContext) {
        assert!(sui::types::is_one_time_witness(&main), 1);
        // todo: needs code to make sure only certain addresses can init
        let admin = DechatAdmin {
            id: object::new(ctx)
        };        
        transfer::transfer(admin, tx_context::sender(ctx));

        let all_posts = AllPosts {
            id: object::new(ctx),
            posts: object_table::new<u64, Post>(ctx),
            response_posts: object_table::new<u64, ResponsePost>(ctx),
            share_posts: object_table::new<u64, SharePost>(ctx)
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

        let post_id = object::new(ctx);
        let chain_agnos_uid = get_uid_str(&post_id);
        let post = Post {
            id: post_id,
            timestamp,
            message,
            chain_agnos_uid
        };

        let posts_length = object_table::length(&all_posts.posts) + 1;
        object_table::add(&mut all_posts.posts, posts_length, post);
    }

    /// @chain should be one of the chain constants listed at top of contract
    entry fun add_response_post_to_all_posts(clock: &Clock, all_posts: &mut AllPosts, profile: &Profile, message: String, chain: String, responding_msg_id: String, ctx: &mut TxContext) {
        let address = tx_context::sender(ctx);
        assert!(address == profile.address, 1);

        let response_post = ResponsePost {
            id: object::new(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            chain: get_supporting_chain(chain),
            responding_msg_id
        };

        let response_posts_length = object_table::length(&all_posts.response_posts) + 1;
        object_table::add(&mut all_posts.response_posts, response_posts_length, response_post);
    }
   
    /// @chain should be one of the chain constants listed at top of contract
    entry fun add_share_post_to_all_posts(clock: &Clock, all_posts: &mut AllPosts, profile: &Profile, message: Option<String>, chain: String, sharing_msg_id: String, ctx: &mut TxContext) {
        let address = tx_context::sender(ctx);
        assert!(address == profile.address, 1);

        let share_post = SharePost {
            id: object::new(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            chain: get_supporting_chain(chain),
            sharing_msg_id
        };

        let share_posts_length = object_table::length(&all_posts.share_posts) + 1;
        object_table::add(&mut all_posts.share_posts, share_posts_length, share_post);
    }

    fun get_uid_str(id: &UID): String {
        utf8(encode(object::uid_to_bytes(id)))
    }

    fun get_supporting_chain(chain: String): SupportingChain {
        if (chain == utf8(SUI)) {
            SupportingChain {
                sui: true,
                aptos: false,
                cosmos: false,
                arweave: false
            }
        } else if (chain == utf8(APTOS)) {
            SupportingChain {
                sui: false,
                aptos: true,
                cosmos: false,
                arweave: false
            }
        } else if (chain == utf8(COSMOS)) {
            SupportingChain {
                sui: false,
                aptos: false,
                cosmos: true,
                arweave: false
            }
        } else {
            SupportingChain {
                sui: false,
                aptos: false,
                cosmos: false,
                arweave: true
            }
        }
    }
    
    #[test]
    fun test_init() {        
        let ctx = tx_context::dummy();

        init(MAIN{}, &mut ctx);
    }

    #[test]
    fun test_create_app_metadata() {
        use sui::test_scenario;

        let admin_address = @0xBABE;

        let original_scenario = test_scenario::begin(admin_address);
        let scenario = &mut original_scenario;
        {
            init(MAIN{}, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, admin_address);
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);
            let version = utf8(b"0.0.1");
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
            init(MAIN{}, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, profile_owner);
        {
            let user_name = utf8(b"dave");
            let full_name = utf8(b"David Choi");
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

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");

        let original_scenario = test_scenario::begin(admin_address);
        let scenario = &mut original_scenario;
        {
            init(MAIN{}, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, profile_owner_address);
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = utf8(b"");
            let profile = Profile {
                id: object::new(ctx),
                address: profile_owner_address,
                user_name,
                full_name,
                description: option::none()
            };
            let all_posts = AllPosts {
                id: object::new(ctx),
                posts: object_table::new<u64, Post>(ctx),
                response_posts: object_table::new<u64, ResponsePost>(ctx),
                share_posts: object_table::new<u64, SharePost>(ctx)
            };
                        
            add_post_to_all_posts(&clock, &mut all_posts, &profile, message, ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_posts);
        };

        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_add_response_post_to_all_posts_on_sui_chain() {
        use sui::test_scenario;
        use std::option;

        let admin_address = @0xBABE;
        let profile_owner_address = @0xCAFE;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");

        let original_scenario = test_scenario::begin(admin_address);
        let scenario = &mut original_scenario;
        {
            init(MAIN{}, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, profile_owner_address);
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = utf8(b"");
            let profile = Profile {
                id: object::new(ctx),
                address: profile_owner_address,
                user_name,
                full_name,
                description: option::none()
            };
            let all_posts = AllPosts {
                id: object::new(ctx),
                posts: object_table::new<u64, Post>(ctx),
                response_posts: object_table::new<u64, ResponsePost>(ctx),
                share_posts: object_table::new<u64, SharePost>(ctx)
            };
                        
            add_response_post_to_all_posts(&clock, &mut all_posts, &profile, message, utf8(SUI), utf8(b"123"), ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_posts);
        };

        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_add_share_post_to_all_posts_on_sui_chain() {
        use sui::test_scenario;
        use std::option;

        let admin_address = @0xBABE;
        let profile_owner_address = @0xCAFE;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");

        let original_scenario = test_scenario::begin(admin_address);
        let scenario = &mut original_scenario;
        {
            init(MAIN{}, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, profile_owner_address);
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = utf8(b"");
            let profile = Profile {
                id: object::new(ctx),
                address: profile_owner_address,
                user_name,
                full_name,
                description: option::none()
            };
            let all_posts = AllPosts {
                id: object::new(ctx),
                posts: object_table::new<u64, Post>(ctx),
                response_posts: object_table::new<u64, ResponsePost>(ctx),
                share_posts: object_table::new<u64, SharePost>(ctx)
            };
                        
            add_share_post_to_all_posts(&clock, &mut all_posts, &profile, option::some(message), utf8(SUI), utf8(b"123"), ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_posts);
        };

        test_scenario::end(original_scenario);
    }
}
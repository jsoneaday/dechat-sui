#[allow(unused_use, unused_field)]
module dechat_sui::main {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object_table;
    use sui::object_table::ObjectTable;
    use sui::clock::{Self, Clock};
    use std::string::{Self, String, utf8};
    use std::option;
    use std::vector;
    use std::option::Option;

    struct MAIN has drop {}

    struct DechatAdmin has key {
        id: UID
    }

    struct AppMetadata has key {
        id: UID,
        timestamp: u64,
        version: String
    }

    #[allow(unused)]
    const SUI: vector<u8> = b"sui";
    const APTOS: vector<u8> = b"aptos";
    const COSMOS: vector<u8> = b"cosmos";
    #[allow(unused)]
    const ARWEAVE: vector<u8> = b"arweave";

    struct ExternalChain has store {
        aptos: bool,
        cosmos: bool,
        arweave: bool
    }

    struct Categorization has key, store {
        id: UID,
        normal: bool,        
        lie: bool,
        misleading: bool,        
        nudity: bool,
        sexual_content: bool,
        violence: bool,
        otherwise_offensive: bool,
    }

    /// color hex value
    struct ProfileFlag has store {
        color: String
    }

    struct Profile has key, store {
        id: UID,
        owner: address,
        user_name: String,
        full_name: String,
        description: Option<String>,
        profile_flag: ProfileFlag
    }

    /// u64 key represents an index value
    struct Post has key, store {
        id: UID,
        owner: address,
        timestamp: u64,
        message: String,
        response_posts: ObjectTable<u64, ResponsePost>,
        share_posts: ObjectTable<u64, SharePost>,
        likes: ObjectTable<u64, Like>,
        dislikes: ObjectTable<u64, DisLike>,
        categorization: ObjectTable<u64, Categorization>
    }

    /// On-chain response post object
    struct ResponsePost has key, store {
        id: UID,
        owner: address,
        timestamp: u64,
        message: String,
        likes: ObjectTable<u64, Like>,
        dislikes: ObjectTable<u64, DisLike>,
        categorization: ObjectTable<u64, Categorization>
    }

    /// Post that responds to a post on an external chain
    /// owner stringified external address
    /// responding_msg_id stringified external data id or address
    struct ExtResponsePost has key, store {
        id: UID,
        owner: address,
        timestamp: u64,
        message: String,
        chain: ExternalChain,
        responding_msg_id: String,
        likes: ObjectTable<u64, Like>,
        dislikes: ObjectTable<u64, DisLike>,
        categorization: ObjectTable<u64, Categorization>
    }
    
    /// On-chain post sharing object
    struct SharePost has key, store {
        id: UID,
        owner: address,
        timestamp: u64,
        message: Option<String>,
        likes: ObjectTable<u64, Like>,
        dislikes: ObjectTable<u64, DisLike>,
        categorization: ObjectTable<u64, Categorization>
    }

    /// Share Post to external foreign chain Posts
    /// owner stringified external address
    /// sharing_msg_id stringified external data id or address
    struct ExtSharePost has key, store {
        id: UID,
        owner: address,
        timestamp: u64,
        message: Option<String>,
        chain: ExternalChain,
        sharing_msg_id: String,
        likes: ObjectTable<u64, Like>,
        dislikes: ObjectTable<u64, DisLike>,
        categorization: ObjectTable<u64, Categorization>
    }

    /// likes on sui chain
    struct Like has key, store {
        id: UID,
        timestamp: u64,
        liker: address
    }

    /// dislikes on sui chain
    struct DisLike has key, store {
        id: UID,
        timestamp: u64,
        disliker: address
    }

    /// likes on foreign chain
    /// liker can be id or address
    /// target asset or address being liked
    struct ExtLike has key, store {
        id: UID,
        timestamp: u64,
        chain: ExternalChain,
        liker: address,
        target: String
    }

    struct ExtDisLike has key, store {
        id: UID,
        timestamp: u64,
        chain: ExternalChain,
        disliker: address,
        target: String
    }

    /// u64 key represents an index value
    struct AllPosts has key, store {
        id: UID,
        posts: ObjectTable<u64, Post>
    }

    struct AllExtResponsePosts has key, store {
        id: UID,
        posts: ObjectTable<u64, ExtResponsePost>
    }

    struct AllExtSharePosts has key, store {
        id: UID,
        posts: ObjectTable<u64, ExtSharePost>
    }

    struct AllExtLikes has key, store {
        id: UID,
        likes: ObjectTable<u64, ExtLike>
    }

    struct AllExtDisLikes has key, store {
        id: UID,
        dislikes: ObjectTable<u64, ExtDisLike>
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
            posts: object_table::new<u64, Post>(ctx)
        };
        transfer::share_object(all_posts);

        let all_ext_response_posts = AllExtResponsePosts {
            id: object::new(ctx),
            posts: object_table::new<u64, ExtResponsePost>(ctx)
        };
        transfer::share_object(all_ext_response_posts);

        let all_ext_share_posts = AllExtSharePosts {
            id: object::new(ctx),
            posts: object_table::new<u64, ExtSharePost>(ctx)
        };
        transfer::share_object(all_ext_share_posts);

        let all_ext_likes = AllExtLikes {
            id: object::new(ctx),
            likes: object_table::new<u64, ExtLike>(ctx)
        };
        transfer::share_object(all_ext_likes);

        let all_ext_dislikes = AllExtDisLikes {
            id: object::new(ctx),
            dislikes: object_table::new<u64, ExtDisLike>(ctx)
        };
        transfer::share_object(all_ext_dislikes);
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
        let owner = tx_context::sender(ctx);

        let profile = Profile {
            id: object::new(ctx),
            owner,
            user_name,
            full_name,
            description,
            profile_flag: ProfileFlag {
                color: utf8(b"#ffffff")
            }
        };

        transfer::share_object(profile);
    }
 
    entry fun add_post_to_all_posts(
        clock: &Clock, 
        all_posts: &mut AllPosts, 
        profile: &Profile, 
        message: String, 
        ctx: &mut TxContext
    ) {
        let timestamp = clock::timestamp_ms(clock);
        let address = tx_context::sender(ctx);
        assert!(address == profile.owner, 1);

        let post_id = object::new(ctx);
        let post = Post {
            id: post_id,
            owner: address,
            timestamp,
            message,
            response_posts: object_table::new<u64, ResponsePost>(ctx),
            share_posts: object_table::new<u64, SharePost>(ctx),
            likes: object_table::new<u64, Like>(ctx),
            dislikes: object_table::new<u64, DisLike>(ctx),
            categorization: object_table::new<u64, Categorization>(ctx)
        };

        let posts_length = object_table::length(&all_posts.posts) + 1;
        object_table::add(&mut all_posts.posts, posts_length, post);
    }

    entry fun add_like_to_post(
        clock: &Clock,
        post: &mut Post,
        profile: &Profile,
        liker: address,
        ctx: &mut TxContext
    ) {
        let timestamp = clock::timestamp_ms(clock);
        let address = tx_context::sender(ctx);
        assert!(address == profile.owner, 1);

        let post_likes_length = object_table::length(&post.likes) + 1;
        object_table::add(&mut post.likes, post_likes_length, Like {
            id: object::new(ctx),
            timestamp,
            liker
        });
    }

    entry fun add_ext_like_to_post(
        clock: &Clock,
        all_ext_likes: &mut AllExtLikes,
        profile: &Profile,
        chain: String,
        liker: address,
        target: String,
        ctx: &mut TxContext
    ) {
        let timestamp = clock::timestamp_ms(clock);
        let address = tx_context::sender(ctx);
        assert!(address == profile.owner, 1);

        let all_ext_likes_length = object_table::length(&all_ext_likes.likes) + 1;
        object_table::add(&mut all_ext_likes.likes, all_ext_likes_length, ExtLike {
            id: object::new(ctx),
            timestamp,
            chain: get_supporting_chain(chain),
            liker,
            target
        });
    }

    entry fun add_dislike_to_post(
        clock: &Clock,
        post: &mut Post,
        profile: &Profile,
        disliker: address,
        ctx: &mut TxContext
    ) {
        let timestamp = clock::timestamp_ms(clock);
        let address = tx_context::sender(ctx);
        assert!(address == profile.owner, 1);

        let post_likes_length = object_table::length(&post.dislikes) + 1;
        object_table::add(&mut post.dislikes, post_likes_length, DisLike {
            id: object::new(ctx),
            timestamp,
            disliker
        });
    }

    entry fun add_ext_dislike_to_post(
        clock: &Clock,
        all_ext_dislikes: &mut AllExtDisLikes,
        profile: &Profile,
        chain: String,
        disliker: address,
        target: String,
        ctx: &mut TxContext
    ) {
        let timestamp = clock::timestamp_ms(clock);
        let address = tx_context::sender(ctx);
        assert!(address == profile.owner, 1);

        let all_ext_dislikes_length = object_table::length(&all_ext_dislikes.dislikes) + 1;
        object_table::add(&mut all_ext_dislikes.dislikes, all_ext_dislikes_length, ExtDisLike {
            id: object::new(ctx),
            timestamp,
            chain: get_supporting_chain(chain),
            disliker,
            target
        });
    }

    entry fun add_response_post_to_post(
        clock: &Clock, 
        post: &mut Post, 
        profile: &Profile, 
        message: String,
        ctx: &mut TxContext
    ) {
        let address = tx_context::sender(ctx);
        assert!(address == profile.owner, 1);

        let response_post = ResponsePost {
            id: object::new(ctx),
            owner: address,
            timestamp: clock::timestamp_ms(clock),
            message,
            likes: object_table::new<u64, Like>(ctx),
            dislikes: object_table::new<u64, DisLike>(ctx),
            categorization: object_table::new<u64, Categorization>(ctx)
        };

        let response_posts_length = object_table::length(&post.response_posts) + 1;
        object_table::add(&mut post.response_posts, response_posts_length, response_post);
    }

    entry fun add_ext_response_post_to_all_ext_response_post(
        clock: &Clock, 
        all_ext_response_posts: &mut AllExtResponsePosts, 
        profile: &Profile, 
        message: String,
        responding_msg_id: String,
        chain: String,
        ctx: &mut TxContext
    ) {
        let address = tx_context::sender(ctx);
        assert!(address == profile.owner, 1);

        let chain = get_supporting_chain(chain);
        let response_post = ExtResponsePost {
            id: object::new(ctx),
            owner: address,
            timestamp: clock::timestamp_ms(clock),
            message,
            chain,
            responding_msg_id,
            likes: object_table::new<u64, Like>(ctx),
            dislikes: object_table::new<u64, DisLike>(ctx),
            categorization: object_table::new<u64, Categorization>(ctx)
        };

        let response_posts_length = object_table::length(&all_ext_response_posts.posts) + 1;
        object_table::add(&mut all_ext_response_posts.posts, response_posts_length, response_post);
    }
   
    /// @chain should be one of the chain constants listed at top of contract
    entry fun add_share_post_to_post(
        clock: &Clock, 
        post: &mut Post, 
        profile: &Profile, 
        message: Option<String>,
        ctx: &mut TxContext
    ) {
        let address = tx_context::sender(ctx);
        assert!(address == profile.owner, 1);

        let share_post = SharePost {
            id: object::new(ctx),
            owner: address,
            timestamp: clock::timestamp_ms(clock),
            message,
            likes: object_table::new<u64, Like>(ctx),
            dislikes: object_table::new<u64, DisLike>(ctx),
            categorization: object_table::new<u64, Categorization>(ctx)
        };

        let share_posts_length = object_table::length(&post.share_posts) + 1;
        object_table::add(&mut post.share_posts, share_posts_length, share_post);
    }

    entry fun add_ext_share_post_to_all_ext_share_post(
        clock: &Clock, 
        all_ext_share_posts: &mut AllExtSharePosts, 
        profile: &Profile, 
        message: Option<String>,
        sharing_msg_id: String,
        chain: String,
        ctx: &mut TxContext
    ) {
        let address = tx_context::sender(ctx);
        assert!(address == profile.owner, 1);

        let chain = get_supporting_chain(chain);
        let share_post = ExtSharePost {
            id: object::new(ctx),
            owner: address,
            timestamp: clock::timestamp_ms(clock),
            message,
            chain,
            sharing_msg_id,
            likes: object_table::new<u64, Like>(ctx),
            dislikes: object_table::new<u64, DisLike>(ctx),
            categorization: object_table::new<u64, Categorization>(ctx)
        };

        let share_posts_length = object_table::length(&all_ext_share_posts.posts) + 1;
        object_table::add(&mut all_ext_share_posts.posts, share_posts_length, share_post);
    }

    #[allow(unused)]
    fun get_supporting_chain(chain: String): ExternalChain {
        if (chain == utf8(APTOS)) {
            ExternalChain {
                
                aptos: true,
                cosmos: false,
                arweave: false
            }
        } else if (chain == utf8(COSMOS)) {
            ExternalChain {
                aptos: false,
                cosmos: true,
                arweave: false
            }
        } else {
            ExternalChain {
                aptos: false,
                cosmos: false,
                arweave: true
            }
        }
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

            let all_posts = test::take_shared<AllPosts>(scenario);
            test::return_shared(all_posts);

            let all_ext_response_posts = test::take_shared<AllExtResponsePosts>(scenario);
            test::return_shared(all_ext_response_posts);

            let all_ext_share_posts = test::take_shared<AllExtSharePosts>(scenario);
            test::return_shared(all_ext_share_posts);

            let all_ext_likes = test::take_shared<AllExtLikes>(scenario);
            test::return_shared(all_ext_likes);

            let all_ext_dislikes = test::take_shared<AllExtDisLikes>(scenario);
            test::return_shared(all_ext_dislikes);
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
    fun test_create_profile() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test};
        use sui::test_utils::assert_eq;
        use std::option;

        let admin = @0xBABE;
        let profile_owner = @0xCAFE;
        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");

        let original_scenario = test_scenario::begin(admin);
        let scenario = &mut original_scenario;
        {
            init(MAIN{}, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, profile_owner);
        {            
            create_profile(user_name, full_name, option::none(), test_scenario::ctx(scenario))
        };

        test_scenario::next_tx(scenario, profile_owner);
        {
            let profile = test::take_shared<Profile>(scenario);
            assert_eq(profile.user_name, user_name);
            assert_eq(profile.full_name, full_name);
            test::return_shared(profile);
        };

        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_add_post_to_all_posts() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");
        let post_message = utf8(b"hello world");

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            
            let profile = Profile {
                id: object::new(ctx),
                owner: profile_owner_address,
                user_name,
                full_name,
                description: option::none(),
                profile_flag: ProfileFlag {
                    color: utf8(b"#ffffff")
                }
            };
            let all_posts = AllPosts {
                id: object::new(ctx),
                posts: object_table::new<u64, Post>(ctx)
            };
                        
            add_post_to_all_posts(&clock, &mut all_posts, &profile, post_message, ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_posts);
        };

        next_tx(scenario, profile_owner_address);
        {
            let all_posts = test::take_shared<AllPosts>(scenario);
            let all_posts_posts_length = object_table::length(&all_posts.posts);
            let last_post = object_table::borrow(&all_posts.posts, all_posts_posts_length);
            assert_eq(last_post.message, post_message);

            test::return_shared(all_posts);
        };

        end(original_scenario);
    }

    #[test]
    fun test_add_like_to_post() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;
        let liker_address = @0x4067;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = utf8(b"hello world");
            let profile = Profile {
                id: object::new(ctx),
                owner: profile_owner_address,
                user_name,
                full_name,
                description: option::none(),
                profile_flag: ProfileFlag {
                    color: utf8(b"#ffffff")
                }
            };
            let post = Post {
                id: object::new(ctx),
                owner: profile_owner_address,
                timestamp: clock::timestamp_ms(&clock),
                message,
                response_posts: object_table::new<u64, ResponsePost>(ctx),
                share_posts: object_table::new<u64, SharePost>(ctx),
                likes: object_table::new<u64, Like>(ctx),
                dislikes: object_table::new<u64, DisLike>(ctx),
                categorization: object_table::new<u64, Categorization>(ctx)
            };
                        
            add_like_to_post(&clock, &mut post, &profile, liker_address, ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(post);
        };

        next_tx(scenario, profile_owner_address);
        {
            let post = test::take_shared<Post>(scenario);
            let post_likes_length = object_table::length(&post.likes);
            let post_likes = object_table::borrow(&post.likes, post_likes_length);
            
            assert_eq(post_likes.liker, liker_address);

            test::return_shared(post);
        };

        end(original_scenario);
    }

    #[test]
    fun test_add_dislike_to_post() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;
        let disliker_address = @0x4067;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            let message = utf8(b"hello world");
            let profile = Profile {
                id: object::new(ctx),
                owner: profile_owner_address,
                user_name,
                full_name,
                description: option::none(),
                profile_flag: ProfileFlag {
                    color: utf8(b"#ffffff")
                }
            };
            let post = Post {
                id: object::new(ctx),
                owner: profile_owner_address,
                timestamp: clock::timestamp_ms(&clock),
                message,
                response_posts: object_table::new<u64, ResponsePost>(ctx),
                share_posts: object_table::new<u64, SharePost>(ctx),
                likes: object_table::new<u64, Like>(ctx),
                dislikes: object_table::new<u64, DisLike>(ctx),
                categorization: object_table::new<u64, Categorization>(ctx)
            };
                        
            add_dislike_to_post(&clock, &mut post, &profile, disliker_address, ctx);

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(post);
        };

        next_tx(scenario, profile_owner_address);
        {
            let post = test::take_shared<Post>(scenario);
            let post_dislikes_length = object_table::length(&post.dislikes);
            let post_dislike = object_table::borrow(&post.dislikes, post_dislikes_length);
            
            assert_eq(post_dislike.disliker, disliker_address);

            test::return_shared(post);
        };

        end(original_scenario);
    }

    #[test]
    fun test_add_response_post_to_post() {
        use sui::test_scenario;
        use sui::test_scenario::{next_tx, Self as test};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");
        let message = utf8(b"hello world");

        let original_scenario = test_scenario::begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);  
            
            let profile = Profile {
                id: object::new(ctx),
                owner: profile_owner_address,
                user_name,
                full_name,
                description: option::none(),
                profile_flag: ProfileFlag {
                    color: utf8(b"#ffffff")
                }
            };
            let all_posts = AllPosts {
                id: object::new(ctx),
                posts: object_table::new<u64, Post>(ctx)
            };

            add_post_to_all_posts(&clock, &mut all_posts, &profile, utf8(b"hello world in post"), ctx);          

            clock::destroy_for_testing(clock);
            transfer::share_object(profile);
            transfer::share_object(all_posts);
        };

        next_tx(scenario, profile_owner_address);
        {
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));
            let profile = test::take_shared<Profile>(scenario);
            let all_posts = test::take_shared<AllPosts>(scenario);
            let all_posts_posts_length = object_table::length(&all_posts.posts);
            let post = object_table::borrow_mut(&mut all_posts.posts, all_posts_posts_length);            

            add_response_post_to_post(&clock, post, &profile, message, test_scenario::ctx(scenario));

            clock::destroy_for_testing(clock);
            test::return_shared(profile);
            test::return_shared(all_posts);
        };

        next_tx(scenario, profile_owner_address);
        {
            let all_posts = test::take_shared<AllPosts>(scenario);
            let all_posts_posts_length = object_table::length(&all_posts.posts);
            let post = object_table::borrow_mut(&mut all_posts.posts, all_posts_posts_length); 
            let post_length = object_table::length(&post.response_posts);
            let response_post = object_table::borrow(&post.response_posts, post_length);

            assert_eq(response_post.message, message);

            test::return_shared(all_posts);
        };
      
        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_add_ext_response_post_to_all_ext_response_post() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test, next_tx};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");
        let message = utf8(b"hello world");

        let original_scenario = test_scenario::begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            
            let profile = Profile {
                id: object::new(ctx),
                owner: profile_owner_address,
                user_name,
                full_name,
                description: option::none(),
                profile_flag: ProfileFlag {
                    color: utf8(b"#ffffff")
                }
            };
            let all_ext_response_posts = AllExtResponsePosts {
                id: object::new(ctx),
                posts: object_table::new<u64, ExtResponsePost>(ctx)
            };
                        
            add_ext_response_post_to_all_ext_response_post(
                &clock, 
                &mut all_ext_response_posts, 
                &profile, 
                message, 
                utf8(b"123"),
                utf8(APTOS),
                ctx
            );

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_ext_response_posts);
        };

        next_tx(scenario, profile_owner_address);
        {
            let all_ext_response_posts = test::take_shared<AllExtResponsePosts>(scenario);
            let all_ext_response_posts_length = object_table::length(&all_ext_response_posts.posts);
            let response_post = object_table::borrow(&all_ext_response_posts.posts, all_ext_response_posts_length);
            assert_eq(response_post.message, message);

            test::return_shared(all_ext_response_posts);
        };

        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_add_ext_like_to_post() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;
        let liker_address = @0x4067;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            
            let profile = Profile {
                id: object::new(ctx),
                owner: profile_owner_address,
                user_name,
                full_name,
                description: option::none(),
                profile_flag: ProfileFlag {
                    color: utf8(b"#ffffff")
                }
            };
            let all_ext_likes = AllExtLikes {
                id: object::new(ctx),
                likes: object_table::new<u64, ExtLike>(ctx)
            };
                        
            add_ext_like_to_post(
                &clock, 
                &mut all_ext_likes, 
                &profile, 
                utf8(b"aptos"), 
                liker_address, 
                utf8(b"123"),
                ctx
            );

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_ext_likes);
        };

        next_tx(scenario, profile_owner_address);
        {
            let all_ext_likes = test::take_shared<AllExtLikes>(scenario);
            let ext_likes_length = object_table::length(&all_ext_likes.likes);
            let like = object_table::borrow(&all_ext_likes.likes, ext_likes_length);
            
            assert_eq(like.liker, liker_address);

            test::return_shared(all_ext_likes);
        };

        end(original_scenario);
    }

    #[test]
    fun test_add_ext_dislike_to_post() {
        use sui::test_scenario;
        use sui::test_scenario::{begin, end, next_tx, Self as test};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;
        let dis_liker_address = @0x4067;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");

        let original_scenario = begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            
            let profile = Profile {
                id: object::new(ctx),
                owner: profile_owner_address,
                user_name,
                full_name,
                description: option::none(),
                profile_flag: ProfileFlag {
                    color: utf8(b"#ffffff")
                }
            };
            let all_ext_dislikes = AllExtDisLikes {
                id: object::new(ctx),
                dislikes: object_table::new<u64, ExtDisLike>(ctx)
            };
                        
            add_ext_dislike_to_post(
                &clock, 
                &mut all_ext_dislikes, 
                &profile, 
                utf8(b"aptos"), 
                dis_liker_address, 
                utf8(b"123"),
                ctx
            );

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_ext_dislikes);
        };

        next_tx(scenario, profile_owner_address);
        {
            let all_ext_dislikes = test::take_shared<AllExtDisLikes>(scenario);
            let ext_dislikes_length = object_table::length(&all_ext_dislikes.dislikes);
            let dislike = object_table::borrow(&all_ext_dislikes.dislikes, ext_dislikes_length);
            
            assert_eq(dislike.disliker, dis_liker_address);

            test::return_shared(all_ext_dislikes);
        };

        end(original_scenario);
    }

    #[test]
    fun test_add_share_post_to_post() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test, next_tx};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");
        let message = utf8(b"hello world");          

        let original_scenario = test_scenario::begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {       
            let ctx = test_scenario::ctx(scenario);                      
            let clock = clock::create_for_testing(ctx);
            
            let profile = Profile {
                id: object::new(ctx),
                owner: profile_owner_address,
                user_name,
                full_name,
                description: option::none(),
                profile_flag: ProfileFlag {
                    color: utf8(b"#ffffff")
                }
            };

            let all_posts = AllPosts {
                id: object::new(ctx),
                posts: object_table::new<u64, Post>(ctx)
            };
            add_post_to_all_posts(&clock, &mut all_posts, &profile, message, ctx);
                        
            clock::destroy_for_testing(clock);
            transfer::share_object(all_posts);            
            transfer::share_object(profile);
        };

        next_tx(scenario, profile_owner_address);
        {
            let clock = clock::create_for_testing(test_scenario::ctx(scenario));

            let all_posts = test::take_shared<AllPosts>(scenario);
            let profile = test::take_shared<Profile>(scenario);
            let posts_length = object_table::length(&all_posts.posts);
            let post = object_table::borrow_mut(&mut all_posts.posts, posts_length);

            add_share_post_to_post(&clock, post, &profile, option::some(message), test_scenario::ctx(scenario));            
            
            clock::destroy_for_testing(clock);
            test::return_shared(all_posts);
            test::return_shared(profile);
        };

        next_tx(scenario, profile_owner_address);
        {          
            let all_posts = test::take_shared<AllPosts>(scenario);
            let posts_length = object_table::length(&all_posts.posts);
            let post = object_table::borrow_mut(&mut all_posts.posts, posts_length);

            let share_posts_length = object_table::length(&post.share_posts);
            let share_post = object_table::borrow(&post.share_posts, share_posts_length);
            assert_eq(share_post.message, option::some(message));

            test::return_shared(all_posts);
        };        
        
        test_scenario::end(original_scenario);
    }

    #[test]
    fun test_add_ext_share_post_to_all_ext_share_post() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test, next_tx};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner_address = @0xCAFE;

        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");
        let message = option::some(utf8(b"hello world"));

        let original_scenario = test_scenario::begin(profile_owner_address);
        let scenario = &mut original_scenario;
        {
            let ctx = test_scenario::ctx(scenario);
            let clock = clock::create_for_testing(ctx);            
            
            let profile = Profile {
                id: object::new(ctx),
                owner: profile_owner_address,
                user_name,
                full_name,
                description: option::none(),
                profile_flag: ProfileFlag {
                    color: utf8(b"#ffffff")
                }
            };
            let all_ext_share_posts = AllExtSharePosts {
                id: object::new(ctx),
                posts: object_table::new<u64, ExtSharePost>(ctx)
            };
                        
            add_ext_share_post_to_all_ext_share_post(
                &clock, 
                &mut all_ext_share_posts, 
                &profile, 
                message, 
                utf8(b"123"),
                utf8(APTOS),
                ctx
            );

            clock::destroy_for_testing(clock);
            transfer::transfer(profile, profile_owner_address);
            transfer::share_object(all_ext_share_posts);
        };

        next_tx(scenario, profile_owner_address);
        {
            let all_ext_share_posts = test::take_shared<AllExtSharePosts>(scenario);
            let all_ext_share_posts_posts_length = object_table::length(&all_ext_share_posts.posts);
            let share_post = object_table::borrow(&all_ext_share_posts.posts, all_ext_share_posts_posts_length);

            assert_eq(share_post.message, message);

            test::return_shared(all_ext_share_posts);
        };

        test_scenario::end(original_scenario);
    }
}
#[allow(unused_use, unused_field)]
module dechat_sui::main {
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use std::string::{Self, String, utf8};
    use std::option;
    use std::vector;
    use std::option::Option;
    use dechat_sui::profile;
    use dechat_sui::profile::{get_profile_user_name, get_profile_full_name, Profile};
    

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

    /// color hex value
    struct ProfileFlag has store {
        color: String
    }

    /// u64 key represents an index value
    struct Post has key, store {
        id: UID,
        owner: address,
        timestamp: u64,
        message: String        
    }

    /// On-chain response post object
    struct ResponsePost has key, store {
        id: UID,
        owner: address,
        timestamp: u64,
        message: String,
        respondee_post_id: ID
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
        respondee_post_id: String
    }
    
    /// On-chain post sharing object
    struct SharePost has key, store {
        id: UID,
        owner: address,
        timestamp: u64,
        message: Option<String>,
        sharee_post_id: ID
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
        sharee_post_id: String
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
        let post_id = object::new(ctx);
        let post = Post {
            id: post_id,
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
            message
        };

        transfer::share_object(post);
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
            post_id: object::uid_to_inner(&post.id)
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
            post_id: object::uid_to_inner(&post.id)
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
        let response_post = ResponsePost {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            respondee_post_id: object::uid_to_inner(&post.id)
        };

        transfer::share_object(response_post);
    }

    entry fun create_ext_response_post(
        clock: &Clock,
        message: String,
        respondee_post_id: String,
        chain: String,
        ctx: &mut TxContext
    ) {
        let chain = get_supporting_chain(chain);
        let response_post = ExtResponsePost {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            chain,
            respondee_post_id
        };

        transfer::share_object(response_post);
    }

    /// @chain should be one of the chain constants listed at top of contract
    entry fun create_share_post(
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
            sharee_post_id: object::uid_to_inner(&post.id)
        };

        transfer::share_object(share_post);
    }

    entry fun create_ext_share_post(
        clock: &Clock,
        message: Option<String>,
        sharee_post_id: String,
        chain: String,
        ctx: &mut TxContext
    ) {
        let chain = get_supporting_chain(chain);
        let share_post = ExtSharePost {
            id: object::new(ctx),
            owner: tx_context::sender(ctx),
            timestamp: clock::timestamp_ms(clock),
            message,
            chain,
            sharee_post_id
        };

        transfer::share_object(share_post);
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
            assert_eq(get_profile_user_name(&profile), user_name);
            assert_eq(get_profile_full_name(&profile), full_name);
            test::return_shared(profile);
        };

        test_scenario::end(original_scenario);
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
            assert_eq(post.message, post_message);

            test::return_shared(post);
        };

        end(original_scenario);
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
            let post = Post {
                id: object::new(ctx),
                owner: profile_owner_address,
                timestamp: clock::timestamp_ms(&clock),
                message
            };
                        
            create_like(&clock, &post, ctx);

            clock::destroy_for_testing(clock);
            transfer::share_object(post);
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
            let post = Post {
                id: object::new(ctx),
                owner: profile_owner_address,
                timestamp: clock::timestamp_ms(&clock),
                message
            };
                        
            create_dislike(&clock, &post, ctx);

            clock::destroy_for_testing(clock);
            transfer::share_object(post);
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

            assert_eq(response_post.message, message);

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
                utf8(APTOS),
                ctx
            );

            clock::destroy_for_testing(clock);
        };

        next_tx(scenario, profile_owner_address);
        {
            let ext_response_post = test::take_shared<ExtResponsePost>(scenario);
            assert_eq(ext_response_post.message, message);

            test::return_shared(ext_response_post);
        };

        test_scenario::end(original_scenario);
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
            assert_eq(share_post.message, option::some(message));

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
                utf8(APTOS),
                ctx
            );

            clock::destroy_for_testing(clock);
        };

        next_tx(scenario, profile_owner_address);
        {
            let ext_share_post = test::take_shared<ExtSharePost>(scenario);

            assert_eq(ext_share_post.message, message);

            test::return_shared(ext_share_post);
        };

        test_scenario::end(original_scenario);
    }
}
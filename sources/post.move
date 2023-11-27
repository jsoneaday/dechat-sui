module dechat_sui::post {
    use sui::object::{Self, UID, ID};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use sui::tx_context;
    use sui::tx_context::TxContext;
    use dechat_sui::utils::{get_supporting_chain, ExternalChain};
    use std::string::{String};    
    use std::option::Option;

    friend dechat_sui::main;
    friend dechat_sui::post_tests;

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

    public(friend) fun get_new_post(
        owner: address,
        timestamp: u64,
        message: String,
        ctx: &mut TxContext
    ): Post {
        Post {
            id: object::new(ctx),
            owner,
            timestamp,
            message
        }
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
            message
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
            respondee_post_id: object::uid_to_inner(&post.id)
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
            respondee_post_id
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
            sharee_post_id: object::uid_to_inner(&post.id)
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
            sharee_post_id
        };

        transfer::share_object(share_post);
    }
}
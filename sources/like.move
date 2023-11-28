module dechat_sui::like {
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::clock::{Self, Clock};
    use sui::transfer;
    use dechat_sui::post::{get_post_id, Post};
    use dechat_sui::utils::{get_supporting_chain, ExternalChain};
    use std::string::String;
    
    friend dechat_sui::main;
    friend dechat_sui::like_tests;

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
}
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

    struct Owner has key, store {
        id: UID,
        address: address,
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

    fun init(_ctx: &mut TxContext) {

    }

    entry fun create_profile(
        ctx: &mut TxContext,
        user_name: String,
        full_name: String,
        description: Option<String>
    ) {
        let address = tx_context::sender(ctx);
        // profile is shared
        let profile = Profile {
            id: object::new(ctx),
            address,
            user_name,
            full_name,
            description
        };

        // owner is ProfileCap to be used later when updating profile or
        // posting messages
        // read activities do not use ProfileCap, only write
        let owner = Owner {
            id: object::new(ctx),
            address
        };
        transfer::transfer(owner, address);

        // init post objects
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

    entry fun add_post_on_profile(clock: &Clock, profile: &mut Profile, owner: &Owner, post: Post) {
        assert!(owner.address == profile.address, 1);

        let post_table = ofield::borrow_mut<vector<u8>, ObjectTable<String, Post>>(
            &mut profile.id, 
            b"fposts"
        );

        add_post(clock, post_table, post);
    }
}
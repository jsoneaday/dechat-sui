module dechat_sui::profile {
    use sui::object::{Self, UID};
    use sui::tx_context;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use std::option::Option;
    use std::string::{String, utf8};

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

    public entry fun create_profile(        
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
}
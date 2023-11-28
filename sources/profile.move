module dechat_sui::profile {
    use sui::object::{Self, UID, ID};
    use sui::tx_context;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::event;
    use std::option::Option;
    use std::string::{String, utf8};

    friend dechat_sui::main;

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

    struct CreateProfileEvent has copy, drop {
        profile_id: ID
    }

    public(friend) fun get_new_profile(owner: address, user_name: String, full_name: String, description: Option<String>, ctx: &mut TxContext): Profile {
        Profile {
            id: object::new(ctx),
            owner,
            user_name,
            full_name,
            description,
            profile_flag: ProfileFlag {
                color: utf8(b"#ffffff")
            }
        }
    }

    public(friend) fun get_profile_owner(profile: &Profile): address {
        profile.owner
    }

    public(friend) fun get_profile_user_name(profile: &Profile): String {
        profile.user_name
    }

    public(friend) fun get_profile_full_name(profile: &Profile): String {
        profile.full_name
    }

    public(friend) fun create_profile(        
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

        event::emit(CreateProfileEvent {
            profile_id: object::uid_to_inner(&profile.id)
        });
        transfer::share_object(profile);
    }

    #[test]
    fun test_create_profile() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test};
        use sui::test_utils::assert_eq;
        use std::option;

        let profile_owner = @0xCAFE;
        let user_name = utf8(b"dave");
        let full_name = utf8(b"David Choi");

        let original_scenario = test_scenario::begin(profile_owner);
        let scenario = &mut original_scenario;
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
}
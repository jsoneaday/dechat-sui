module dechat_sui::follower {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::event;

    friend dechat_sui::main;

    struct Follower has key, store {
        id: UID,
        profile_follower_id: ID,
        profile_followee_id: ID
    }

    struct CreateProfileFollowerEvent has copy, drop {        
        profile_follower_id: ID,
        profile_followee_id: ID
    }

    public(friend) fun create_follower(
        profile_follower_id: ID,
        profile_followee_id: ID,
        ctx: &mut TxContext
    ) {
        let follower = Follower {
            id: object::new(ctx),
            profile_follower_id,
            profile_followee_id
        };

        event::emit(CreateProfileFollowerEvent {
            profile_follower_id,
            profile_followee_id
        });
        transfer::share_object(follower);
    }

    #[test]
    fun test_create_follower() {
        use sui::test_scenario;
        use sui::test_scenario::{Self as test};

        let profile_follower = @0xCAFE;

        let original_scenario = test_scenario::begin(profile_follower);
        let scenario = &mut original_scenario;
        {
            let follower_id = object::new(test_scenario::ctx(scenario));
            let followee_id = object::new(test_scenario::ctx(scenario));

            create_follower(object::uid_to_inner(&follower_id), object::uid_to_inner(&followee_id), test_scenario::ctx(scenario));

            object::delete(follower_id);
            object::delete(followee_id);
        };

        test_scenario::next_tx(scenario, profile_follower);
        {
            let follower = test::take_shared<Follower>(scenario);
            test::return_shared(follower);
        };

        test_scenario::end(original_scenario);
    }
}
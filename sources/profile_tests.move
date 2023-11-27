#[test_only]
module dechat_sui::profile_tests {
    use dechat_sui::profile::{Profile, create_profile, get_profile_full_name, get_profile_user_name};
    use std::string::utf8;

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
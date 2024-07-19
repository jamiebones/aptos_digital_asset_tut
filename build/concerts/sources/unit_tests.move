#[test_only]
module tickets::unit_tests {
    use aptos_framework::object;
    use aptos_framework::account;
    use aptos_framework::timestamp;
    use std::signer;
    use std::string::{Self};
    use aptos_framework::object::Object;
    use aptos_token_objects::collection;
    use tickets::tickets;
    use tickets::tickets::TicketToken;



    const GOLD_TICKET: vector<u8> = b"Gold";
    const SILVER_TICKET: vector<u8> = b"Silver";
    const BRONZE_TICKET: vector<u8> = b"Bronze";


    fun setup_test(
        creator: &signer,
        owner_1: &signer,
        owner_2: &signer,
        aptos_framework: &signer,
    ) {
        timestamp::set_time_has_started_for_testing(aptos_framework);
        account::create_account_for_test(signer::address_of(aptos_framework));
        account::create_account_for_test(signer::address_of(creator));
        account::create_account_for_test(signer::address_of(owner_1));
        account::create_account_for_test(signer::address_of(owner_2));
        tickets::create_ticket_collection(creator);
    }

    #[test(creator = @tickets, owner_1 = @0xA, owner_2 = @0xB, aptos_framework = @0x1)]
    fun test_token_creation(
        creator: &signer,
        owner_1: &signer,
        owner_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test(creator, owner_1, owner_2, aptos_framework);

        let owner_1_addr = signer::address_of(owner_1);
        let owner_2_addr = signer::address_of(owner_2);
        // mint 1 token to each of the 2 owner accounts
        let token_1_constructor_ref = tickets::mint_ticket_token(creator, string::utf8(b"Token #1"), owner_1_addr, string::utf8(GOLD_TICKET));
        let token_2_constructor_ref = tickets::mint_ticket_token(creator, string::utf8(b"Token #2"), owner_2_addr, string::utf8(SILVER_TICKET));

        let token_1_obj: Object<TicketToken> = object::object_from_constructor_ref(&token_1_constructor_ref);
        let token_2_obj: Object<TicketToken> = object::object_from_constructor_ref(&token_2_constructor_ref);
        assert!(object::owner(token_1_obj) == owner_1_addr, 400);
    }

    #[test(creator = @tickets, owner_1 = @0xA, owner_2 = @0xB, aptos_framework = @0x1)]
    fun check_token_properties(
        creator: &signer,
        owner_1: &signer,
        owner_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test(creator, owner_1, owner_2, aptos_framework);

        let owner_1_addr = signer::address_of(owner_1);
        let creator_addr = signer::address_of(creator);
        let token_1_constructor_ref = tickets::mint_ticket_token(creator, string::utf8(b"Token #1"), owner_1_addr, string::utf8(GOLD_TICKET));
        let token_1_obj: Object<TicketToken> = object::object_from_constructor_ref(&token_1_constructor_ref);
        assert!(tickets::view_ticket_type(token_1_obj) == string::utf8(GOLD_TICKET), 600);
        assert!(tickets::view_ticket_status(token_1_obj) == false, 601);

        assert!(tickets::get_total(creator_addr) == 1, 100);
    }

    #[test(creator = @tickets, owner_1 = @0xA, owner_2 = @0xB, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 131074 , location = aptos_token_objects::collection)]
    fun should_enforce_maximum_token_number(
        creator: &signer,
        owner_1: &signer,
        owner_2: &signer,
        aptos_framework: &signer,
    ) {
        setup_test(creator, owner_1, owner_2, aptos_framework);

        let owner_1_addr = signer::address_of(owner_1);
        let owner_2_addr = signer::address_of(owner_2);
        tickets::mint_ticket_token(creator, string::utf8(b"Token #1"), owner_1_addr, string::utf8(GOLD_TICKET));
        tickets::mint_ticket_token(creator, string::utf8(b"Token #2"), owner_2_addr, string::utf8(GOLD_TICKET));
        tickets::mint_ticket_token(creator, string::utf8(b"Token #3"), owner_2_addr, string::utf8(GOLD_TICKET));
    }

    //E11001

}
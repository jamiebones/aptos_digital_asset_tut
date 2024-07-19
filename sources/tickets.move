
module tickets::tickets {

    use std::string::{Self, String};
    use std::signer;
    use aptos_framework::object::{Self, Object, ConstructorRef};
    use std::option::{Self, Option};
    use aptos_token_objects::collection;
    use aptos_token_objects::token;
    use aptos_token_objects::property_map;
    use aptos_framework::event;
    use std::timestamp;


    //ERROR

    const E_NOT_THE_OWNER: u64 = 211;
    const E_WRONG_TICKET: u64 = 212;
    const E_WRONG_TICKET_STATUS: u64 = 213;
    const ETOKEN_DOES_NOT_EXIST: u64 = 404;
    const ENOT_CREATOR: u64 = 206;


    const COLLECTION_NAME: vector<u8> = b"Sporting Event Ticket";
    const COLLECTION_DESCRIPTION: vector<u8> = b"This is a collection of tickets in an event";
    const COLLECTION_URI: vector<u8> = b"http://Igonowhere.com";
    const BASE_URI: vector<u8> = b"http://Igonowhere.com";
    const MAX_SUPPLY: u64 = 2;



    /// Ticket type
    const GOLD_TICKET: vector<u8> = b"Gold";
    const SILVER_TICKET: vector<u8> = b"Silver";
    const BRONZE_TICKET: vector<u8> = b"Bronze";


    #[event]
    struct TicketMinted has drop, store {
        owner: address,
        minted_date: u64
    }

    struct Config has key {
        number: u64
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// The ticket token
    struct TicketToken has key {
        /// Used to mutate properties
        property_mutator_ref: property_map::MutatorRef,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    /// The ticket type
    struct TicketType has key {
        ticket_type: String,

    }


    fun init_module(creator: &signer) {
        create_ticket_collection(creator);

    }


    public fun create_ticket_collection(creator: &signer) {
        // Constructs the strings from the bytes.
        let description = string::utf8(COLLECTION_DESCRIPTION);
        let collection_name = string::utf8(COLLECTION_NAME);
        let uri = string::utf8(COLLECTION_URI);

        //creates a collection that has a fixed number of tokens
        let constructor_ref = collection::create_fixed_collection(
            creator,
            description,
            MAX_SUPPLY,
            collection_name,
            option::none(),
            uri
        );
        move_to(creator, Config { number: 0 });
    }


    public fun mint_ticket_token(
        creator: &signer,
        name: String,
        receipient: address,
        ticket_type: String
    ): ConstructorRef acquires Config {
        // The collection name is used to locate the collection object and to create a new token object.
        let collection = string::utf8(COLLECTION_NAME);

        // Creates the ticket token, and get the constructor ref of the token. The constructor ref
        // is used to generate the refs of the token.
        let uri = string::utf8(BASE_URI);
        let description = string::utf8(COLLECTION_DESCRIPTION);

        assert!(exists<Config>(signer::address_of(creator)), 900);
        let numberMinted = borrow_global_mut<Config>(signer::address_of(creator));
        let constructor_ref: ConstructorRef = token::create_named_token(creator, collection,
            description, name, option::none(), uri);
        // Generates the object signer and the refs. The object signer is used to publish a resource
        let object_signer = object::generate_signer(&constructor_ref);
        let transfer_ref = object::generate_transfer_ref(&constructor_ref);
        let property_mutator_ref = property_map::generate_mutator_ref(&constructor_ref);

        // Transfers the token to the receipient address
        let linear_transfer_ref = object::generate_linear_transfer_ref(&transfer_ref);
        object::transfer_with_ref(linear_transfer_ref, receipient);

        // Disables ungated transfer, thus making the token soulbound and non-transferable
        object::disable_ungated_transfer(&transfer_ref);

        move_to(&object_signer, TicketType { ticket_type});

        let properties = property_map::prepare_input(vector[], vector[], vector[]);
        property_map::init(&constructor_ref, properties);
        property_map::add_typed(
            &property_mutator_ref,
            string::utf8(b"Ticket_Used"),
            false
        );

        // Publishes the TicketToken resource with the refs.
        let ticket_token = TicketToken {
            property_mutator_ref,
        };
        move_to(&object_signer, ticket_token);
        numberMinted.number = numberMinted.number + 1;
        event::emit(
            TicketMinted{
                owner: receipient,
                minted_date: timestamp::now_microseconds()
            }
        );
        constructor_ref
    }

    public entry fun use_ticket(
        token: Object<TicketToken>
    ) acquires TicketToken {
        let token_address = object::object_address(&token);
        let ticket_token = borrow_global<TicketToken>(token_address);
        let property_mutator_ref = &ticket_token.property_mutator_ref;
        property_map::update_typed(property_mutator_ref, &string::utf8(b"Ticket_Used"), true);
    }

    #[view]
    /// Returns the type of the token
    public fun view_ticket_status(token: Object<TicketToken>): bool {
        property_map::read_bool(&token, &string::utf8(b"Ticket_Used"))
    }

    #[view]
    /// Returns the ticket type of the token
    public fun view_ticket_type(token: Object<TicketToken>): String acquires TicketType {
        let ticket_type = borrow_global<TicketType>(object::object_address(&token));
        ticket_type.ticket_type
    }

    #[view]
    public fun get_total(addr: address): u64 acquires Config {
        assert!(exists<Config>(addr), 800);
        borrow_global<Config>(addr).number
    }

}

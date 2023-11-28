module dechat_sui::utils {
    use sui::object::{Self, UID, ID};
    use std::string::{String, utf8};
    use std::option::Option;

    friend dechat_sui::main;
    friend dechat_sui::post;
    friend dechat_sui::post_tests;
    friend dechat_sui::like;

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

    #[allow(unused)]
    public(friend) fun get_supporting_chain(chain: String): ExternalChain {
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
}
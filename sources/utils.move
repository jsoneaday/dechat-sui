#[allow(unused_use)]
module dechat_sui::utils {    
    use sui::object::Self;
    use std::string::{String, utf8};

    friend dechat_sui::main;
    friend dechat_sui::post;
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

    #[allow(unused)]
    struct Categorization has store {
        normal: bool,        
        lie: bool,
        misleading: bool,        
        nudity: bool,
        sexual_content: bool,
        violence: bool,
        otherwise_offensive: bool,
    }

    public(friend) fun get_new_categorization(): Categorization {
        Categorization {
            normal: true,
            lie: false,
            misleading: false,        
            nudity: false,
            sexual_content: false,
            violence: false,
            otherwise_offensive: false
        }
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
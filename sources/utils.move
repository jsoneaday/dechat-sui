module dechat_sui::utils {
    use std::string::{String, utf8};

    friend dechat_sui::main;
    friend dechat_sui::post;
    friend dechat_sui::post_tests;

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
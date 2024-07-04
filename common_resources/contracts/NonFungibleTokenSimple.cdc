/*
    This interface implements the rules to define NFTs only. There are no Collections set at this point. These should be set in a different interface
    @rdlalmeida 07/02/2023
*/
pub contract interface NonFungibleTokenSimple {
    // Simple interface to define the NFT resources
    pub resource interface INFT {
        /*
            Require only a unique id for each NFT. Now, here's the thing I need to consider: if I'm going to have different types of NFTs in the same collection, these need to
            have unique ids in that Collection at least. So, how can I enforce this given that these NFTs can be created by multiple independent contracts? Well, as an initial
            approach, why not set the id as a String that is the result of the concatenation of the NFT type (also as a String, duh...) and an uuid, as always? Let's try it
            out and see what happens
        */ 
        pub let id: String

        /*
            To enforce the new id setting, I'm going to add a new function to the interface that essentially builds the ID String as I've defined above. How can I be sure that
            the user implements this function properly? I can't... Just like implementing the original NonFungibleToken interface ensures that an NFT created under it does 
            ensure that the id UInt64 is unique for every NFT created. Developers are free to do whatever they want in that case. Anyone can create a contract that creates all
            NFTs with an id = 666 for all they care. But when they try to deposit these into a NonFungibleToken-based Collection, it blows up after the first deposit because
            dictionaries, which are used to store these NFTs internally, don't like repetitive keys. And the same applies to my case!
        */

        // Function the should be used to produce an unique String ID, ideally by concatenating the NFT type with a uuid value. But ultimately this detail falls on the contract developer.
        pub fun createID(): String
    }

    // And now the resource itself
    pub resource NFT: INFT {
        pub let id: String
        pub fun createID(): String
    }
}
 
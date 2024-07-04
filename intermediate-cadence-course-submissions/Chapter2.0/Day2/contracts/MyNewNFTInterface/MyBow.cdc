import NonFungibleTokenSimple from "../../../../../common_resources/contracts/NonFungibleTokenSimple.cdc"

pub contract MyBow: NonFungibleTokenSimple {
    pub resource NFT: NonFungibleTokenSimple.INFT {
        pub let id: String
        pub let name: String

        pub fun createID(): String {
            // As expected, for these kinds of NFTs, the id String is going to be a concatenation of the contract type, which is also the NFT type,
            // concatenated with an uuid to ensure uniqueness within this NFT type
            return (self.getType().identifier).concat(self.uuid.toString())
        }

        init() {
            // The NFT is is now obtained with the createID function created above.
            self.name = "Bow"
            self.id = self.createID()
            
        }
    }

    // If all goes well, I can define the minting function just like with the other standardized way, limiting it also to access(account) as before
    access(account) fun createBow(): @NFT {
        return <- create NFT()
    }

    // And its done! This is the reason why I wanted to split the NonFungibleToken contract interface into two, so that I don't need to implement
    // all the remaining crap, which is useless in this context.
    // I have to setup another "extra" contract to setup the Collection but, overall, I only need to implement the Collection stuff in a single contract
    // instead of having to repeat that code in each NFT contract
}
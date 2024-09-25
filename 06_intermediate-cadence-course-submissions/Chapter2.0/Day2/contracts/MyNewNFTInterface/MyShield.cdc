import NonFungibleTokenSimple from "../../../../../common_resources/contracts/NonFungibleTokenSimple.cdc"

pub contract MyShield: NonFungibleTokenSimple {
    // This one is just a reply of the Bow.cdc contract. Check that one for detais
    pub resource NFT: NonFungibleTokenSimple.INFT {
        pub let id: String
        pub let name: String

        pub fun createID(): String {
            return (self.getType().identifier).concat(self.uuid.toString())
        }

        init() {
            self.name = "Shield"
            self.id = self.createID()
        }
    }

    access(account) fun createShield(): @NFT {
        return <- create NFT()
    }
}
 
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

pub contract ResourceTypes {
    pub event NFTMinted(id: UInt64, type: String)
    pub event CollectionCreated(user: Address?, type: String)
    pub event Withdraw(id: UInt64, from: Address?, type: String)
    pub event Deposit(id: UInt64, to: Address?, type: String)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let MinterPublicPath: PublicPath

    pub resource ExampleResource {
        pub let name: String

        init(name: String) {
            self.name = name
        }
    }

    // Since the NonFungibleToken is an INTERFACE (I keep forgetting that...), I need to setup the collection creation logic somewhere else, like here for
    // example

    // pub resource interface CollectionPublic {
    //     pub fun deposit(token: @NonFungibleToken.NFT)
    //     pub fun getIDs(): [UInt64]
    //     pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    // }

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64

        init() {
            self.id = self.uuid
        }
    }

    // Create a Collection based ONLY on the NonFungibleToken interface (don't need the custom CollectionPublic Interface... I think)
    pub resource Collection: NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
        //     let token: @NonFungibleToken.NFT <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
        //     emit Withdraw(id: token.id, from: self.owner?.address, type: token.getType().identifier)
        //     return <- token
        // }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            emit Deposit(id: token.id, to: self.owner?.address, type: token.getType().identifier)
            self.ownedNFTs[token.id] <-! token
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // Finally, the function that creates an Empty Collection from this contract, but its one that follows the NonFungibleToken Interface
    pub fun createEmptyCollection (): @Collection {
        let newCollection: @Collection <- create Collection()
        emit CollectionCreated(user: self.account.address, type: newCollection.getType().identifier)
        return <- newCollection
    }

    // Now for the Minter stuff too
    pub resource Minter {
        pub fun createNFT(): @NFT {
            let newNFT: @NFT <- create NFT()
            emit NFTMinted(id: newNFT.id, type: newNFT.getType().identifier)
            return <- newNFT
        }
        
    }

    pub fun createExampleResource(name: String): @ExampleResource {
        return <- create ExampleResource(name: name)
    }

    init() {
        self.CollectionStoragePath = /storage/myCollection
        self.CollectionPublicPath = /public/myCollection
        self.MinterStoragePath = /storage/myMinter
        self.MinterPublicPath = /public/myMinter

        self.account.unlink(self.MinterPublicPath)
        let oldMinter: @AnyResource <- self.account.load<@AnyResource>(from: self.MinterStoragePath)
        destroy oldMinter

        self.account.save(<- create Minter(), to: self.MinterStoragePath)
        self.account.link<&Minter>(self.MinterPublicPath, target: self.MinterStoragePath)
    }
}
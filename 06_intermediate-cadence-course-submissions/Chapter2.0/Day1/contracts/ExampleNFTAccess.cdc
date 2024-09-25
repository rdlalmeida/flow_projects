import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

pub contract ExampleNFTAccess {
    pub let AdminStorage: StoragePath

    pub let collectionStorage: StoragePath
    pub let collectionPublicStorage: PublicPath

    pub event CollectionLocked(message: String)
    pub event CollectionUnlocked(message: String)

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub let name: String
        pub let description: String

        init(name: String, description: String) {
            self.id = self.uuid
            self.name = name
            self.description = description
        }
    }

    pub resource interface CollectionPublic {
        pub let collectionName: String
        access(contract) fun lock()
        access(contract) fun unlock()
        pub fun withdraw(withdrawID: UInt64): String
    }

    pub resource Collection: CollectionPublic {
        pub let collectionName: String
        pub var locked: Bool
        pub var ownedNFTs: @{UInt64: NFT}

        pub fun withdraw(withdrawID: UInt64): String {
            // pre {
            //     !self.locked: "Collection ".concat(self.collectionName).concat("is locked! You cannot withdraw NFTs.")
            // }

            // let nft: @NFT <- self.ownedNFTs.remove(key: withdrawID)
            //     ?? panic("This NFT doesn't exist in this collection")
            
            // return <- nft

            // Return this String just to indicate that the function works (No need to return a NFT for this case)
            
            // This is a bastardization of the withdraw function just for testing purposes
            if (self.locked) {
                return "Collection ".concat(self.collectionName).concat(" is locked! No NFTs for you ah ah ah ah !!")
            }

            return "NFT with id ".concat(withdrawID.toString()).concat("is withdrawble! That means the collection ".concat(self.collectionName).concat(" is not locked! Cool!"))
        }

        access(contract) fun lock() {
            self.locked = true
            emit CollectionLocked(message: "Collection ".concat(self.collectionName).concat(" is now locked!"))
        }

        access(contract) fun unlock() {
            self.locked = false
            emit CollectionUnlocked(message: "Collection ".concat(self.collectionName).concat(" was unlocked!"))
        }

        init(collectionName: String) {
            self.collectionName = collectionName
            self.locked = false
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub resource Admin {
        // Simple function to lock a user's collection
        pub fun lockUserCollection(collection: &Collection{CollectionPublic}) {
            collection.lock()
        }

        // Same but to unlock
        pub fun unlockUserCollection(collection: &Collection{CollectionPublic}) {
            collection.unlock()
        }

    }

    pub fun createEmptyCollection(collectionName: String): @Collection {
        return <- create Collection(collectionName: collectionName)
    }

    init() {
        self.AdminStorage = /storage/Admin
        self.collectionStorage = /storage/myCollection
        self.collectionPublicStorage = /public/myPublicCollection

        let randomAdmin: @AnyResource <- self.account.load<@AnyResource>(from: self.AdminStorage)
        destroy randomAdmin

        // Create and store an Admin resource, which is only accessible by the contract deployer
        let admin: @Admin <- create Admin()

        self.account.save(<- admin, to: self.AdminStorage)
    }
}
 
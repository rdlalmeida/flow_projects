import NonFungibleToken from "../../../../../common_resources/contracts/NonFungibleToken.cdc"

pub contract StandardBow: NonFungibleToken {
    pub var totalSupply: UInt64    
    pub event ContractInitialized()

    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event MintBowNFT(id: UInt64)

    pub let collectionStorage: StoragePath
    pub let collectionPublic: PublicPath

    pub event BowCollectionCreated()

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub let type: String

        init() {
            self.id = self.uuid
            self.type = "Bow"
        }
    }

    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowBowNFT(id: UInt64): &StandardBow.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow the reference: The ID of the returned Bow reference is incorrect"
            }
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let nftToRemove: @NonFungibleToken.NFT <- self.ownedNFTs.remove(key: withdrawID) ??
                panic("NFT with id ".concat(withdrawID.toString()).concat(" does not exist in the collection!"))

                return <- nftToRemove
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token: @StandardBow.NFT <- token as! @StandardBow.NFT
            emit Deposit(id: token.id, to: self.owner!.address)
            self.ownedNFTs[token.id] <-! token
        }

        pub fun borrowBowNFT(id: UInt64): &StandardBow.NFT? {
            if (self.ownedNFTs[id] != nil) {
                let ref: auth &NonFungibleToken.NFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!

                // Up cast the reference and return it
                return (ref as! &StandardBow.NFT)
            }

            return nil
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // Use this function to create a Bow NFT
    access(account) fun createBow(): @NFT {
        let bowNFT: @NFT <- create NFT()
        emit MintBowNFT(id: bowNFT.id)
        return <- bowNFT
    }

    pub fun createEmptyCollection(): @Collection {
        let collection: @Collection <- create Collection()
        emit BowCollectionCreated()
        return <- collection
    }

    init() {
        self.totalSupply = 0
        self.collectionStorage = /storage/standardBowStorage
        self.collectionPublic = /public/standardBowStorage
        emit ContractInitialized()
    }
}
 
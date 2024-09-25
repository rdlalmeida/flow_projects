import NonFungibleToken from "../../../../../common_resources/contracts/NonFungibleToken.cdc"

pub contract StandardShield: NonFungibleToken {
    pub var totalSupply: UInt64
    pub event ContractInitialized()

    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event MintShieldNFT(id: UInt64)

    pub let collectionStorage: StoragePath
    pub let collectionPublic: PublicPath

    pub event ShieldCollectionCreated()

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub let type: String

        init() {
            self.id = self.uuid
            self.type = "Shield"
        }
    }

    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowShieldNFT(id: UInt64): &StandardShield.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow the reference: the ID of the returned Shield reference is incorrect"
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
            let nftToWithdraw: @NonFungibleToken.NFT <- self.ownedNFTs.remove(key: withdrawID) ??
                panic("NFT with id ".concat(withdrawID.toString()).concat(" does not exists."))

                return <- nftToWithdraw
        }
        
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token: @StandardShield.NFT <- token as! @StandardShield.NFT
            emit Deposit(id: token.id, to: self.owner!.address)
            self.ownedNFTs[token.id] <-! token
        }

        pub fun borrowShieldNFT(id: UInt64): &StandardShield.NFT? {
            if (self.ownedNFTs[id] != nil) {
                let ref: auth &NonFungibleToken.NFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return (ref as! &StandardShield.NFT)
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

    // And this one to create Shield NFTs
    access(account) fun createShield(): @NFT {
        let shieldNFT: @NFT <- create NFT()
        emit MintShieldNFT(id: shieldNFT.id)
        return <- shieldNFT
    }

    pub fun createEmptyCollection(): @Collection {
        let collection: @Collection <- create Collection()
        emit ShieldCollectionCreated()
        return <- collection
    }

    init() {
        self.totalSupply = 0
        self.collectionStorage = /storage/standardShieldStorage
        self.collectionPublic = /public/standardShieldStorage
        emit ContractInitialized()
    }
}

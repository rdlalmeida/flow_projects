import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
// import NonFungibleToken from 0xf8d6e0586b0a20c7

pub contract Record: NonFungibleToken {
    pub var totalSupply: UInt64

    pub event ContractInitialized()
    pub event NFTMinted(songName: String)
    pub event CollectionCreated(user: Address?)
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)

    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub let songName: String

        init(songName: String) {
            self.id = self.uuid
            self.songName = songName
            Record.totalSupply = Record.totalSupply + 1
        }
    }

    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowRecordNFT(id: UInt64): &Record.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow the reference: the ID of the returned reference is incorrect"
            }
        }
    }

    pub resource Collection: CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token: @NonFungibleToken.NFT <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Missing NFT")
            emit Withdraw(id: token.id, from: self.owner?.address)
            return <- token
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token: @Record.NFT <- token as! @Record.NFT
            emit Deposit(id: token.id, to: self.owner?.address)
            self.ownedNFTs[token.id] <-! token
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowRecordNFT(id: UInt64): &Record.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref: auth &NonFungibleToken.NFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                return ref as! &Record.NFT
            }

            return nil
        }

        init () {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub resource Minter {
        pub fun createRecord(songName: String): @Record.NFT {
            let newNFT: @Record.NFT <- create Record.NFT(songName: songName)
            emit NFTMinted(songName: songName)
            return <- newNFT
        }
    }

    pub fun createEmptyCollection(): @Record.Collection {
        let newCollection: @Record.Collection <- create Collection()
        emit CollectionCreated(user: self.account.address)
        return <- newCollection
    }



    init() {
        self.totalSupply = 0
        
        self.CollectionStoragePath = /storage/RecordCollection
        self.CollectionPublicPath = /public/RecordCollection
        self.MinterStoragePath = /storage/Minter

        // Retrieve any old minters from the storage path
        let oldMinter: @AnyResource <- self.account.load<@AnyResource>(from: self.MinterStoragePath)
        // And destroy it to clear the storage path
        destroy oldMinter


        // Create and save a brand new Minter resource
        self.account.save(<- create Minter(), to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}
 
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

pub contract TestNFT: NonFungibleToken {
    pub var totalSupply: UInt64
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event MintTestNFT(id: UInt64)

    pub let collectionStorage: StoragePath
    pub let collectionPublic: PublicPath

    pub event CollectionCreated()

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub let type: String

        init() {
            self.id = self.uuid
            self.type = self.getType().identifier
        }
    }

    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowTestNFT(id: UInt64): &TestNFT.NFT? {
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow the reference: The ID of the returned TestNFT reference is incorrect"
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
                panic("NFT with id ".concat(withdrawID.toString()).concat(" does not exists in the Collection!"))

            return <- nftToRemove
        }

        // Play around with this one to see if I can enforce/relax types
        pub fun deposit(token: @NonFungibleToken.NFT) {
            // Lets try the "normal" version first
            // let token: @TestNFT.NFT <- token as! @TestNFT.NFT
            let token: @NonFungibleToken.NFT <- token
            emit Deposit(id: token.id, to: self.owner!.address)
            self.ownedNFTs[token.id] <-! token
        }

        pub fun borrowTestNFT(id: UInt64): &TestNFT.NFT? {
            if (self.ownedNFTs[id] != nil) {
                let ref: auth &NonFungibleToken.NFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
                // let ref: &NonFungibleToken.NFT = (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!

                log("borrowTestNFT: Ref type before downcast: ".concat(ref.getType().identifier))

                // return (ref as! &TestNFT.NFT)

                let downcastRef: &TestNFT.NFT = ref as! &TestNFT.NFT

                log("borrowTestNFT: downcastRef type is now: ".concat(downcastRef.getType().identifier))

                return downcastRef

                /*
                    This is the output of the sequence of logs above, when I mint a @TestNFT.NFT, deposit it, still as @TestNFT.NFT,
                    using the deposit function in the format as in this file, i.e., as a NonFungibleToken.NFT and not explicitely as
                    @TokenNFT.NFT, and then borrow it with this function:

                    DEBU[12810] LOG [a7bafc] "borrowTestNFT: Ref type before downcast: A.f8d6e0586b0a20c7.TestNFT.NFT" 
                    DEBU[12810] LOG [a7bafc] "borrowTestNFT: downcastRef type is now: A.f8d6e0586b0a20c7.TestNFT.NFT"

                    The lesson here: even if I deposit the token as an assumed general type NonFungibleToken.NFT, internally
                    it is indeed a TestNFT.NFT in any case! Yes, if I downcast it on deposit it is technically more correct, I
                    guess, but this means that I can store multiple NFT types (to an extent) in a single Collection if I don't do
                    this, as longa s I write a dedicated borrow function for each. This means also that when I create a Collection, 
                    it has to be prepared to receive a specific set of types before hand, denoted by the set of different borrow functions.
                    My theory was right after all!
                */
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

    pub fun createEmptyCollection(): @Collection {
        let collection: @Collection <- create Collection()
        emit CollectionCreated()
        return <- collection
    }

    access(account) fun createTestNFT(): @NFT {
        let testNFT: @NFT <- create NFT()
        emit MintTestNFT(id: testNFT.id)
        return <- testNFT
    }

    init() {
        self.totalSupply = 0
        self.collectionStorage = /storage/testCollection
        self.collectionPublic = /public/testCollection

        emit ContractInitialized()
    }
}
 
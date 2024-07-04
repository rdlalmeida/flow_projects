import NonFungibleToken from "../../../../../common_resources/contracts/NonFungibleToken.cdc"

pub contract StandardSword: NonFungibleToken {
    pub var totalSupply: UInt64
    pub event ContractInitialized()

    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event MintSwordNFT(id: UInt64)

    pub let collectionStorage: StoragePath
    pub let collectionPublic: PublicPath

    pub event SwordCollectionCreated()

    pub resource NFT: NonFungibleToken.INFT {
        pub let id: UInt64
        pub let type: String

        init() {
            self.id = self.uuid
            self.type = "Sword"
        }
    }

    // Create this extra interface just to add a reference retrieval function to get NFT of this specific type
    /*
        Another important NOTE: Apparently, the Collection public interface, which is used to add the borrowSwordNFT(id: UInt64): &StandardSword.NFT? function
        as a complement to the original, NonFungibleToken.Collection interface, NEEDS to match the original NonFungibleToken.Collection interface.
        Why, I have no idea at this point. I've tried to define this CollectionPublic interface with just the borrowSwordNFT function, and it does not works.
        Later on, when I try to deposit one of these NFTs into a Collection (as a reference), it says no way. I had to complement this CollectionPublic interface
        for the deposit function to be available.
        The way I see it, look at the full signature of the Collection resource: It implements the Receiver, Provider and then the CollectionPublic from the
        main NonFungibleToken interface. But looking at the NonFungibleToken.Collection interface, this one "repeats" the deposit and withdraw functions
        defined in the Provider and Receiver interfaces and adds the getIDs and borrowNFT functions. In fact, the NonFungibleToken.CollectionPublic omits
        the withdraw function from it to prevent random users from withdrawing NFTs from a user's Collection, by obvious reasons!
        This is tricky but eventually I'm going to understand this properly. 
    */
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowSwordNFT(id: UInt64): &StandardSword.NFT? {
            post {
                (result == nil) || (result?.id == id): 
                    "Cannot borrow the reference: The ID of the returned Sword reference is incorrect"
            }
        }
    }

    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let nftToRemove: @NonFungibleToken.NFT <- self.ownedNFTs.remove(key: withdrawID) ??
                panic("NFT with id ".concat(withdrawID.toString()).concat(" does not exist in this collection"))
                emit Withdraw(id: nftToRemove.id, from: self.owner?.address)
                return <- nftToRemove
        }

        pub fun deposit(token: @NonFungibleToken.NFT) {
            /*
                VERY IMPORTANT: The token to deposit arrives generalized as NonFungibleToken.NFT but its to be deposited as a more specific
                StandardSword.NFT token! This has to happen in order for the borrowSwordNFT() function to work! Otherwise the upcast stuff
                is going to FAIL!!!
                Why does this has to happen? Because the NonFungibleToken interfaces forces the internal collection paramenter "ownedNFTs" to
                accept NonFungibleToken.NFT types. But, apparently, you can save more specific types of NFTs, as long as properly casted first.
                This function exploits this functionality to go around this apparent limitation
                NOTE: This was fucking up my whole logic, simply because I forgot to add this cast to the deposit function, so I was depositing
                NonFungibleToken.NFS's, instead of the more specific StandardSword.NFT. So, when I tried to retrived an authorized reference and
                upcast it, it made big, big pooh-pohh!
            */
            let token: @StandardSword.NFT <- token as! @StandardSword.NFT
            emit Deposit(id: token.id, to: self.owner!.address)
            self.ownedNFTs[token.id] <-! token
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        pub fun borrowSwordNFT(id: UInt64): &StandardSword.NFT? {
            // Proceed with the auth reference and respective up casting only if there's a non nil NFT in the internal array
            if (self.ownedNFTs[id] != nil) {
                // Get the reference as a authorized one for the lower type (I think) so that I can up cast it to the desired type to return
                let ref: auth &NonFungibleToken.NFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!

                // Now that I have the auth reference, upcast it and return it
                return ref as! &StandardSword.NFT
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

    // Use this function to create a Sword NFT
    access(account) fun createSword(): @NFT {
        let swordNFT: @NFT <- create NFT()
        emit MintSwordNFT(id: swordNFT.id)
        return <- swordNFT
    }

    pub fun createEmptyCollection(): @Collection {
        let collection: @Collection <- create Collection()
        emit SwordCollectionCreated()
        return <- collection
    }

    init() {
        self.totalSupply = 0
        self.collectionStorage = /storage/standardSwordStorage
        self.collectionPublic = /public/standardSwordStorage
        emit ContractInitialized()

    }
}
 
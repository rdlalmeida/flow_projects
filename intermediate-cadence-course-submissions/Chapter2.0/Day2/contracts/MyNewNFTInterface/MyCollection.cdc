import NonFungibleTokenCollection from "../../../../../common_resources/contracts/NonFungibleTokenCollection.cdc"
import NonFungibleTokenSimple from "../../../../../common_resources/contracts/NonFungibleTokenSimple.cdc"
import MyBow from "./MyBow.cdc"
import MyShield from "./MyShield.cdc"
import MySword from "./MySword.cdc"

pub contract MyCollection: NonFungibleTokenCollection {
    pub var totalSupply: UInt64
    
    pub event ContractInitialized()
    pub event Withdraw(id: String, from: Address?)
    pub event Deposit(id: String, to: Address?)

    pub event TokenTypeAdded(tokenType: Type, count: Int)
    pub event TokenTypeRemoved(tokenType: Type, count: Int)
    pub event InexistentTokenType(tokenType: Type)
    pub event InexistentTokenID(tokenType: Type, tokenID: String)

    pub event MyCollectionCreated()
    pub event MintMyNFT(id: String)

    pub let myCollectionStorage: StoragePath
    pub let myCollectionPublic: PublicPath

    // Use this interface to add custom functions tailored to this context, or limit the usage of others
    // In this particular case, because I want to store Bow, Shield and Sword NFTs in the same collection, I'm going to add three specific borrow functions,
    // one per NFT type to return. I tried to write it first in a single function, but I'm not sure that is possible. 
    pub resource interface CollectionPublic {
        pub fun deposit(token: @NonFungibleTokenSimple.NFT)
        pub fun getIDs(): [String]
        pub fun getAllTokenTypes(): [Type]
        pub fun getAllTokenIDs(tokenType: Type): [String]?
        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT
        pub fun borrowBowNFT(id: String): &MyBow.NFT
        pub fun borrowShieldNFT(id: String): &MyShield.NFT
        pub fun borrowSwordNFT(id: String): &MySword.NFT
    }

    // Now the main Collection
    pub resource Collection: NonFungibleTokenCollection.Provider, NonFungibleTokenCollection.Receiver, NonFungibleTokenCollection.CollectionPublic, CollectionPublic {
        pub var ownedNFTs: @{String: NonFungibleTokenSimple.NFT}
        pub var tokenTypeCount: {Type: [String]}

        // Implement the new set of functions to deal with the tokenType dictionary
        pub fun addTokenType(tokenType: Type, tokenId: String): Void {
            // Check if the entry already exists.
            if (self.tokenTypeCount[tokenType] != nil) {
                // Increment the entry by 1 in this case
                self.tokenTypeCount[tokenType]!.append(tokenId)
                emit TokenTypeAdded(tokenType: tokenType, count: self.tokenTypeCount[tokenType]!.length)
            }
            else {
                // Initialize a new dictionary entry to 1 in this case
                self.tokenTypeCount[tokenType] = [tokenId]
                emit TokenTypeAdded(tokenType: tokenType, count: 1)
            }
        }

        pub fun removeTokenType(tokenType: Type, tokenId: String): Void {
            // In this one, check if the entry already exists first
            if (self.tokenTypeCount[tokenType] == nil) {
                // Emit the corresponding event
                emit InexistentTokenType(tokenType: tokenType)
                // Nothing else to do in this case.
                return
            }
            else {
                // There are some entries in the dictionary. Check if any matches the tokenID to remove
                if (self.tokenTypeCount[tokenType]!.contains(tokenId)) {
                    // Remove the element and emit the event
                    self.tokenTypeCount[tokenType]!.remove(at: self.tokenTypeCount[tokenType]!.firstIndex(of: tokenId)!)

                    // Check if the array for that tokenType became empty after the last remove. If so, remove the dictionary entry too and
                    // emit the Event accordingly
                    if (self.tokenTypeCount[tokenType]!.length == 0) {
                        emit TokenTypeRemoved(tokenType: tokenType, count: 0)

                        // I've only did this branch in order to remove the dictionary entry
                        self.tokenTypeCount.remove(key: tokenType)
                    }
                    else {
                        // In this case, emit the event with the new array size
                        emit TokenTypeRemoved(tokenType: tokenType, count: self.tokenTypeCount[tokenType]!.length)
                    }
                }
                else {
                    // In this case, the tokenType dictionary entry exists but does not have the provided tokenID.
                    // Emit the corresponding event and move on
                    emit InexistentTokenID(tokenType: tokenType, tokenID: tokenId)
                }
            }

        }

        pub fun getAllTokenTypes(): [Type] {
            // This one is easy, just like the getIDs one
            return self.tokenTypeCount.keys
        }

        pub fun getAllTokenIDs(tokenType: Type): [String]? {
            // If the tokenType entry does not exists yet, the function returns a nil instead
            return self.tokenTypeCount[tokenType]
        }

        pub fun getIDs(): [String] {
            return self.ownedNFTs.keys
        }

        // I anticipate that most of my problems are going to be coming for this deposit function, so go ahead and write it at the top
        // Unlike the other Collections, this one cannot downcast the received NFT, i.e., tokens, by default, are stored as NonFungibleTokenSimple.NFT
        pub fun deposit(token: @NonFungibleTokenSimple.NFT) {
            // Start by adding the new type to the tokenTypeCount
            self.addTokenType(tokenType: token.getType(), tokenId: token.id)

            // Every token,regardless of the type, is stored as a NonFungibleTokenSimple.NFT type. I've tested it and this do not removes the
            // underlying, more specific type
            let token: @NonFungibleTokenSimple.NFT <- token
            emit Deposit(id: token.id, to: self.owner!.address)

            // Add it to the main dictionary lastly
            self.ownedNFTs[token.id] <-! token
        }

        // Next, the specific borrow functions
        pub fun borrowBowNFT(id: String): &MyBow.NFT {
            // Check first if anything is in that storage spot
            let tokenOptionalRef: auth &NonFungibleTokenSimple.NFT? = &self.ownedNFTs[id] as auth &NonFungibleTokenSimple.NFT?
            if (tokenOptionalRef == nil) {
                panic("The Collection does not have any Bow NFT with id ".concat(id))
            }

            // Now that I know that there's something there, remove the optional
            let tokenRef: auth &NonFungibleTokenSimple.NFT = tokenOptionalRef!

            // Check if the id is compatible with the NFT to return. The isInstance function should be perfect for this
            if (!tokenRef.isInstance(Type<@MyBow.NFT>())) {
                panic("The token with id ".concat(id).concat(" is not of the required type: ").concat(Type<@MyBow.NFT>().identifier))
            }

            // Seems that everything is in order if the code gets to this point. Downcast and return the reference
            return tokenRef as! &MyBow.NFT
        }

        // Rinse and repeat for the remaining NFT types
        pub fun borrowShieldNFT(id: String): &MyShield.NFT {
            let tokenOptionalRef: auth &NonFungibleTokenSimple.NFT? = &self.ownedNFTs[id] as auth &NonFungibleTokenSimple.NFT?
            if (tokenOptionalRef == nil) {
                panic("The Collection does not have any Shield NFT with id ".concat(id))
            }

            let tokenRef: auth &NonFungibleTokenSimple.NFT = tokenOptionalRef!

            if (!tokenRef.isInstance(Type<@MyShield.NFT>())) {
                panic("The token with id ".concat(id).concat(" is not of the required type: ").concat(Type<@MyShield.NFT>().identifier))
            }

            return tokenRef as! &MyShield.NFT
        }

        pub fun borrowSwordNFT(id: String): &MySword.NFT {
            let tokenOptionalRef: auth &NonFungibleTokenSimple.NFT? = &self.ownedNFTs[id] as auth &NonFungibleTokenSimple.NFT?
            if (tokenOptionalRef == nil) {
                panic("The Collection does not have any Sword NFT with id ".concat(id))
            }

            let tokenRef: auth &NonFungibleTokenSimple.NFT = tokenOptionalRef!

            if (!tokenRef.isInstance(Type<@MySword.NFT>())) {
                panic("The token with id ".concat(id).concat(" is not of the required type: ").concat(Type<@MySword.NFT>().identifier))
            }

            return tokenRef as! &MySword.NFT
        }

        pub fun withdraw(withdrawID: String): @NonFungibleTokenSimple.NFT {
            let token: @NonFungibleTokenSimple.NFT <- self.ownedNFTs.remove(key: withdrawID) ??
                panic("NFT with id ".concat(withdrawID).concat(" does not exist in this collection!"))
            emit Withdraw(id: withdrawID, from: self.owner?.address)

            // Remove the token entry from the tokenTypeCount dictionary too, before returning the token
            self.removeTokenType(tokenType: token.getType(), tokenId: token.id)

            // Return the token
            return <- token
        }

        pub fun borrowNFT(id: String): &NonFungibleTokenSimple.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleTokenSimple.NFT?)!
        }

        init() {
            self.ownedNFTs <- {}
            self.tokenTypeCount = {}
        }

        destroy () {
            destroy self.ownedNFTs
        }
    }

    pub fun createEmptyCollection(): @Collection {
        let newCollection: @Collection <- create Collection()
        emit MyCollectionCreated()
        return <- newCollection
    }

    init() {
        self.totalSupply = 0
        self.myCollectionStorage = /storage/myCollection
        self.myCollectionPublic = /public/myCollection

        emit ContractInitialized()
    }
}
 
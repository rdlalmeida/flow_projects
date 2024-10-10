/* 
    TODO: The VoteBooth needs a different type of collection. Or none whatsoever, given that I need to ensure that users can own one and only one vote at a time. Collections can simplify the transfer of tokens between contracts since it adds a decent level of assurance that the correct token is tranferred into the user's account.

    TODO: Validate if this thing can or cannot import the contracts directly from the provider (local emulator). When I try to do it, the damn thing complains that it cannot find the import. Because I really need the import to carry with the rest of the contract, I have to do a "manual" import, i.e., using a file path, to get rid of the warnings. Switch the import to the emulator one and run this again to see if it works. - DONE
*/
import "NonFungibleToken"
import "MetadataViews"

access(all) contract AnotherNFT: NonFungibleToken {
    // STORAGE PATHS
    access(all) let minterStoragePath: StoragePath
    access(all) let collectionStoragePath: StoragePath
    access(all) let collectionPublicPath: PublicPath

    // CUSTOM EVENT
    // This event should be emitted when a 'nil' is expected but something else is returned instead
    access(all) event NonNilTokenReturned(tokenType: Type)

    // AUXILIARY STRUCTURES

    /**
        The basic NFT construct, i.e., a Resource in this context.
     */
    access(all) resource NFT: NonFungibleToken.NFT {
        access(all) let id: UInt64

        init () {
            // Get the random and automatically generated unique id
            self.id = self.uuid
        }

        /*
            NOTE: With the new Crescendo upgrade, it now seems that every NFT definition that uses the NonFungibleToken standard has to implement a 'createEmptyCollection' function IN THE NFT DEFINITION. This is new since this used to be a requirement for the contract only, but it appears that the token themselves have to contain this function as well with the new rules.
        */
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create AnotherNFT.Collection();
        }

        // ViewResolver.Resolver
        access(all) view fun getViews(): [Type] {
            // Return the MetadataViews stuff
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.Editions>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>(),
                Type<MetadataViews.Serial>()
            ]
        }

        // ViewResolver.Resolver
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: "AnotherNFT example... of another NFT",
                        description: "Another example of a NFT contract, as many, many others, just to see how this thing works",
                        thumbnail: MetadataViews.HTTPFile(
                            url: "Use this field to set up URLs to external digital resources"
                        )
                    )
                case Type<MetadataViews.Editions>():
                    // The max edition field can be used to limit the number of NFTs that can be
                    // minted with this contract. Setting this value to nil removes minting limits
                    let editionInfo = MetadataViews.Edition(name: "AnotherNFT edition 1", number: self.id, max: nil)
                    let editionList: [MetadataViews.Edition] = [editionInfo]
                    return MetadataViews.Editions(
                        editionList
                    )
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.id
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return AnotherNFT.resolveContractView(resourceType: Type<@AnotherNFT.NFT>(), viewType: Type<MetadataViews.NFTCollectionData>())
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return AnotherNFT.resolveContractView(resourceType: Type<@AnotherNFT.NFT>(), viewType: Type<MetadataViews.NFTCollectionDisplay>())
            }
            // The default case is a nil return, aparently...
            return nil
        }
    }

    /**
       The Resource that creates the NFTs. This one needs to be handled with care
    */
    access(all) resource NFTMinter {
        access(all) fun createNFT(): @NFT {
            return <- create NFT();
        }

        init() {}
    }

    access(all) resource Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        access(contract) var supportedTypes: {Type:Bool}

        // NonFungibleToken.Receiver
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return self.supportedTypes
        }

        // NonFungibleToken.Receiver
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            // The '!' is used to resolve a potential Bool?
            if (self.supportedTypes[type]!) {
                return true
            }

            return false
        }

        // NonFungibleToken.Receiver
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            /*
                First, try to force cast the token received, which has an outer type 'NonFungibleTokenN.NFT', into the narrower 'AnotherNFT.NFT'. This should be OK but panic if a 'nil' was obtained instead.
                'Normal' casts use the 'as' term. Forcefull ones use 'as!'
            */
            let token: @AnotherNFT.NFT <- token as! @AnotherNFT.NFT

            /*
                So, there's a non-zero probability that something might be present in the storage space in question. The correct way to send stuff to any internal mapping (in Cadence these are called dictionaires) is to, first, move whatever might be in the position in question to a temporary variable, hence why this variable is named 'randomResource' and has the 'AnyResource?' type because there's a 99.99% probability of getting a 'nil' instead (that's what the '?' is for), and move in the new resource in this rare 3 parameter statement.
            */
            let randomResource: @AnyResource? <- self.ownedNFTs[token.id] <- token
            
            /*
                Because I'm picky, I always test the stuff that I got back from the dictionary and annoy the user if something other than a 'nil' was returned into the randomResource thingy
            */
            if (randomResource != nil) {
                // Emit the relevant event
                emit NonNilTokenReturned(tokenType: randomResource.getType())
            }
            
            // Finish the function by destroying the resource. Even if this one is a nil, it still needs to be destroyed.
            destroy randomResource
        }

        // NonFungibleToken.Collection
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            /*
                Grab a reference (not the resource itself) to the resource in the 'id' position from the internal dictionary. If there's nothing stored in self.ownedNFTs[id], this statement results in a 'nil'
            */
            let tokenRef: &{NonFungibleToken.NFT}? = &self.ownedNFTs[id]

            return tokenRef
        }

        // NonFungibleToken.Provider
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token: @{NonFungibleToken.NFT} <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Unable to retrieve token with id ".concat(withdrawID.toString()))

            return <-token
        }

        // NonFungibleToken.Collection
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create AnotherNFT.Collection()
        }

        // Use this constructor to set up the supported types and other structures that are set to be
        // unchanged during the contract's lifetime
        init() {
            self.ownedNFTs <- {}
            
            // Initialize the dictionary of supported types
            self.supportedTypes = {}

            // And add all the ones I wish to support
            /*
                Type() is a system function that, when provided with a resource, it returns the type of it. Since I'm using a type as key for this dictionary, I'm getting it by running Type<@AnotherNFT.NFT>() to get the type required.
            */
            self.supportedTypes[Type<@AnotherNFT.NFT>()] = true
        }
    }

    // ViewResolver
    // Gets a list of views for all the NFTs defined by this contract
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [
            Type<MetadataViews.NFTCollectionData>(),
            Type<MetadataViews.NFTCollectionDisplay>()
        ];
    }

    // ViewResolver
    // Resolves a view that applies to all the NFTs defined by this contract
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                let collectionData: MetadataViews.NFTCollectionData = MetadataViews.NFTCollectionData(
                    storagePath: self.collectionStoragePath,
                    publicPath: self.collectionPublicPath,
                    publicCollection: Type<&AnotherNFT.Collection>(),
                    publicLinkedType: Type<&AnotherNFT.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <- AnotherNFT.createEmptyCollection(nftType: Type<@AnotherNFT.NFT>())
                    })
                )
                return collectionData
            
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media: MetadataViews.Media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(
                        url: "Add a SVG+XML link here"
                    ),
                    mediaType: "image/svg+xml"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "AnotherNFT Example Collection",
                    description: "This collection is used as an example to help develop NFT frameworks in Flow",
                    externalURL: MetadataViews.ExternalURL("Insert links here"),
                    squareImage: media,
                    bannerImage: media,
                    socials: {
                        "github": MetadataViews.ExternalURL("Add the link to the Github project here")
                    }
                )
        }
        // Default
        return nil
    }

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        // Create a Collection resource so that I can test its supported types
        let collection: @AnotherNFT.Collection <- create Collection()

        // Use the resource to see if the type provided is one of the supported ones
        if (collection.isSupportedNFTType(type: nftType)) {
            // If so, return the collection resource
            return <- collection
        }
        else {
            // Otherwise, destroy it and panic
            destroy collection
            panic("This contract does not support collection from type ".concat(nftType.identifier).concat("!"))
        }
    }
    
    init() {
        self.minterStoragePath = /storage/NFTMinter
        self.collectionStoragePath = /storage/AnotherCollection
        self.collectionPublicPath = /public/AnotherCollection

        // Create a minter resource and immediately save it to the contract account's storage. 
        // This function runs only once during deployment and only the contract can access this
        // resource. This is how Flow protects the minting resource.
        self.account.storage.save(<- create NFTMinter(), to: self.minterStoragePath)
    }
}
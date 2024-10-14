import "NonFungibleToken"
import "MetadataViews"

access(all) contract ExampleNFTContract: NonFungibleToken {
    access(all) let MinterStoragePath: StoragePath
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath

    // Custom Events
    access(all) event NFTMinted(tokenId: UInt64)

    access(all) resource ExampleNFT: NonFungibleToken.NFT {
        access(all) let id: UInt64

        // These fields are not that relevant for now, but I need to implement these function to implement the standard
        access(all) view fun getViews(): [Type] {
            return [
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- ExampleNFTContract.createEmptyCollection(nftType: Type<@ExampleNFTContract.ExampleNFT>())
        }
        
        init() {
            self.id = self.uuid
        }
    }
    
    access(all) resource NFTMinter {
        access(all) fun createNFT(): @ExampleNFT {
            let newToken: @ExampleNFT <- create ExampleNFT()

            emit NFTMinted(tokenId: newToken.id)

            return <- newToken
        }

        init() {

        }
    }

    access(all) resource Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[Type<@ExampleNFTContract.ExampleNFT>()] = true

            return supportedTypes
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@ExampleNFTContract.ExampleNFT>()
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let token: @ExampleNFTContract.ExampleNFT <- token as! @ExampleNFTContract.ExampleNFT

            let id: UInt64 = token.id

            let oldToken: @AnyResource? <- self.ownedNFTs[token.id] <- token

            destroy oldToken
        }

        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let token: @{NonFungibleToken.NFT} <- self.ownedNFTs.remove(key: withdrawID) ??
            panic(
                "ExampleNFTContract.Collection.withdraw: Could not withdraw an NFT with ID"
                .concat(withdrawID.toString())
                .concat(". Check the submitted ID to make sure it is one that this collection owns."))

            return <- token
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- ExampleNFTContract.createEmptyCollection(nftType: Type<@ExampleNFTContract.ExampleNFT>())
        }

        init() {
            self.ownedNFTs <- {}
        }
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return []
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        return nil
    }

    access(all) fun createEmptyCollection(nftType: Type):@{NonFungibleToken.Collection} {
        return <- create Collection()
    }


    init() {
        self.MinterStoragePath = /storage/exampleMinter
        self.CollectionStoragePath = /storage/exampleNFTCollection
        self.CollectionPublicPath = /public/exampleNFTCollection

        // TODO: Added the type of resource to store. Check if this might resolve the minting problem I was getting before
        self.account.storage.save<@ExampleNFTContract.NFTMinter>(<- create NFTMinter(), to: self.MinterStoragePath)
    }
}
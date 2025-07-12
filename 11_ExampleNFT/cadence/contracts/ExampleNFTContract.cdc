import "NonFungibleToken"

access(all) contract ExampleNFTContract: NonFungibleToken {
    access(all) let MinterStoragePath: StoragePath
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath

    access(all) resource ExampleNFT: NonFungibleToken.NFT {
        access(all) let id: UInt64
        access(all) let uri: String


        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            let collection: @{NonFungibleToken.Collection} <- ExampleNFTContract.createEmptyCollection(nftType: Type<@ExampleNFTContract.ExampleNFT>())
            return <- collection
        }
        
        access(all) view fun getViews(): [Type] {
            // Emit the events fist before returning the result
            return []}

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil}
        
        init(_uri: String) {
            self.id = self.uuid
            self.uri = _uri
        }
    }
    
    access(all) resource NFTMinter {
        access(all) fun createNFT(uri: String): @ExampleNFT {
            let newToken: @ExampleNFT <- create ExampleNFT(_uri: uri)
            return <- newToken
        }

        init() {}
    }

    access(all) resource Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let token: @ExampleNFTContract.ExampleNFT <- token as! @ExampleNFTContract.ExampleNFT

            // let id: UInt64 = token.id

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


        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[Type<@ExampleNFTContract.ExampleNFT>()] = true

            return supportedTypes
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@ExampleNFTContract.ExampleNFT>()
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            let collection: @{NonFungibleToken.Collection} <- ExampleNFTContract.createEmptyCollection(nftType: Type<@ExampleNFTContract.ExampleNFT>())
            return <- collection
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

    access(all) fun saySomething(): String {
        return "This contract is working!"
    }

    access(all) fun sayThings(things: String): String {
        return "Words are being concatenated: ".concat(things);
    }


    init() {
        self.MinterStoragePath = /storage/exampleMinter
        self.CollectionStoragePath = /storage/exampleNFTCollection
        self.CollectionPublicPath = /public/exampleNFTCollection

        // Clean the storage spot for the Minter in storage first. Whenever I amend a deployed contract, the Minter never gets deleted after deleting the contract
        let randomMinter: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.MinterStoragePath);

        // Destroy whatever may have been in storage to clear the space for the new Minter
        destroy randomMinter

        // TODO: Added the type of resource to store. Check if this might resolve the minting problem I was getting before
        self.account.storage.save<@ExampleNFTContract.NFTMinter>(<- create NFTMinter(), to: self.MinterStoragePath)
    }
}
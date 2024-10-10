import "AnotherNFT"

transaction() {

    let collectionRef: &AnotherNFT.Collection?

    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {
        self.collectionRef = signer.storage.borrow<&AnotherNFT.Collection>(from: AnotherNFT.collectionStoragePath)

        if (self.collectionRef == nil) {
            signer.storage.save(<- AnotherNFT.createEmptyCollection(nftType: Type<@AnotherNFT.NFT>()), to: AnotherNFT.collectionStoragePath)
        }
        else {
            log(
                "Account "
                .concat(signer.address.toString())
                .concat(" already has a Collection in storage!")
            )
        }

        var storageCapabilities: Capability<&AnotherNFT.Collection>? = signer.capabilities.get<&AnotherNFT.Collection>(AnotherNFT.collectionPublicPath)

        if (storageCapabilities == nil) {

            storageCapabilities = signer.capabilities.storage.issue<&AnotherNFT.Collection>(AnotherNFT.collectionStoragePath)
            
            signer.capabilities.publish(storageCapabilities!, at: AnotherNFT.collectionPublicPath)
        }
    }

    execute {

    }
}
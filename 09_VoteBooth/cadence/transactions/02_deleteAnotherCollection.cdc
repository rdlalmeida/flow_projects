import "AnotherNFT"

transaction() {
    let collectionRef: &AnotherNFT.Collection?

    prepare(signer: auth(BorrowValue, LoadValue, UnpublishCapability) &Account) {
        self.collectionRef = signer.storage.borrow<&AnotherNFT.Collection>(from: AnotherNFT.collectionStoragePath)

        if (self.collectionRef != nil) {
            let result: Capability? = signer.capabilities.unpublish(AnotherNFT.collectionPublicPath)

            log("Unpublish capability result: ")
            log(result)
        }

        let oldCollection: @AnotherNFT.Collection? <- signer.storage.load<@AnotherNFT.Collection>(from: AnotherNFT.collectionStoragePath)

        if (oldCollection != nil) {
            log(
                "Found a collection in account "
                .concat(signer.address.toString())
                .concat(". Destroying it...")
            )
        }

        destroy oldCollection
    }

    execute {

    }
}
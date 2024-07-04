import StandardBow from "../contracts/StandardNFTInterface/StandardBow.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Clean up storage, just in case
        let randomCollection: @AnyResource <- signer.load<@AnyResource>(from: StandardBow.collectionStorage)
        destroy randomCollection
        signer.unlink(StandardBow.collectionPublic)

        // Create, save and link a new Collection
        let collection: @StandardBow.Collection <- StandardBow.createEmptyCollection()
        signer.save(<- collection, to: StandardBow.collectionStorage)
        signer.link<&StandardBow.Collection>(StandardBow.collectionPublic, target: StandardBow.collectionStorage)
    }

    execute {

    }
}
 
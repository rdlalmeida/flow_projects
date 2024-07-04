import ExampleNFTAccess from "../contracts/ExampleNFTAccess.cdc"

transaction(collectionName: String) {
    prepare(signer: AuthAccount) {

        signer.unlink(ExampleNFTAccess.collectionPublicStorage)
        let randomCollection: @AnyResource <- signer.load<@AnyResource>(from: ExampleNFTAccess.collectionStorage)
        destroy randomCollection

        // Create and save a new Collection to the user's account
        let newCollection: @ExampleNFTAccess.Collection{ExampleNFTAccess.CollectionPublic} <- ExampleNFTAccess.createEmptyCollection(collectionName: collectionName)

        // Save and link it to the user's account
        signer.save(<- newCollection, to: ExampleNFTAccess.collectionStorage)
        signer.link<&ExampleNFTAccess.Collection{ExampleNFTAccess.CollectionPublic}>(ExampleNFTAccess.collectionPublicStorage, target: ExampleNFTAccess.collectionStorage)
    }

    execute {
    }
}
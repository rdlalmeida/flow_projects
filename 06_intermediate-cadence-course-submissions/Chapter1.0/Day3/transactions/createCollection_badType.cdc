import ExampleNFT from "../../../../common_resources/contracts/ExampleNFT.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Create a collection but do so without defining a specific type but specifying the interface that it must conform to
        // FUN FACT: If the type of the Collection is not specified, Cadence doesn't bother you about casting the output from the createEmptyCollection(). But if you do
        // and the return and expected types don't match, Cadence tells you about it and forces the downcast
        let collection: @AnyResource{NonFungibleToken.CollectionPublic} <- ExampleNFT.createEmptyCollection()

        signer.unlink(/public/badTypeCollection)
        let randomResource: @AnyResource <- signer.load<@AnyResource>(from: /storage/badTypeCollection)
        destroy randomResource

        // Save and link the Collection as before
        signer.save(<- collection, to: /storage/badTypeCollection)
        signer.link<&AnyResource{NonFungibleToken.CollectionPublic}>(/public/badTypeCollection, target: /storage/badTypeCollection)
    }

    execute {

    }
}
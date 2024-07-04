import ExampleNFT from "../../../../common_resources/contracts/ExampleNFT.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Create the collection resource. This is where the scripts in question may fail or not: the setup of the main resource (and the link operation later on)
        // NOTE: Since the createEmptyCollection function returns a NonFungibleToken.Collection, the resulting resource needs to be downcasted to the proper type
        let collection: @ExampleNFT.Collection{ExampleNFT.CollectionPublic} <- ExampleNFT.createEmptyCollection() as! @ExampleNFT.Collection

        signer.unlink(/public/Collection)
        let randomResource: @AnyResource <- signer.load<@AnyResource>(from: /storage/Collection)
        destroy randomResource

        // Save it and link it
        signer.save(<- collection, to: /storage/Collection)
        signer.link<&ExampleNFT.Collection{ExampleNFT.CollectionPublic}>(/public/Collection, target: /storage/Collection)
    }

    execute {

    }
}
 
import ExampleNFT from "../../../../common_resources/contracts/ExampleNFT.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let storageCollection: StoragePath = /storage/Collection
        let publicCollection: PublicPath = /public/Collection

        let randomCollection: @AnyResource <- signer.load<@AnyResource>(from: storageCollection)
        destroy(randomCollection)

        signer.unlink(publicCollection)

        let newCollection: @NonFungibleToken.Collection <- ExampleNFT.createEmptyCollection()

        signer.save<@NonFungibleToken.Collection>(<- newCollection, to: storageCollection)
        signer.link<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>(publicCollection, target: storageCollection)
    }

    execute {

    }
}
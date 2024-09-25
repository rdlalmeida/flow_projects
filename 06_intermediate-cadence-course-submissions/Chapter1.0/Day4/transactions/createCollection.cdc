import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import ResourceTypes from "../contracts/ResourceTypes.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Same old same old...
        let collectionStoragePath: StoragePath = /storage/myCollection
        let collectionPublicPath: PublicPath = /public/myCollection

        // unlink and clean up the storage path
        signer.unlink(collectionPublicPath)
        let randomResource: @AnyResource <- signer.load<@AnyResource>(from: collectionStoragePath)
        destroy randomResource

        let newCollection: @ResourceTypes.Collection{NonFungibleToken.CollectionPublic} <- ResourceTypes.createEmptyCollection()

        signer.save<@ResourceTypes.Collection{NonFungibleToken.CollectionPublic}>(<- newCollection, to: ResourceTypes.CollectionStoragePath)

        // Now, when linking it to the public, omit the main type and specify only the interface
        signer.link<&{NonFungibleToken.CollectionPublic}>(ResourceTypes.CollectionPublicPath, target: ResourceTypes.CollectionStoragePath)

    }

    execute {

    }
}
 
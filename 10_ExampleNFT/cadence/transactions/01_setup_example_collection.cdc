import "ExampleNFTContract"
import "NonFungibleToken"

transaction() {
    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {
        if (signer.storage.borrow<&ExampleNFTContract.Collection>(from: ExampleNFTContract.CollectionStoragePath) != nil) {
            log(
                "Account "
                .concat(signer.address.toString())
                .concat(" already has a Collection in storage!")
            )
            return
        }

        let collection: @{NonFungibleToken.Collection} <- ExampleNFTContract.createEmptyCollection(nftType: Type<@ExampleNFTContract.ExampleNFT>())

        signer.storage.save(<- collection, to: ExampleNFTContract.CollectionStoragePath)

        let collectionCap: Capability<&ExampleNFTContract.Collection> = signer.capabilities.storage.issue<&ExampleNFTContract.Collection>(ExampleNFTContract.CollectionStoragePath)

        signer.capabilities.publish(collectionCap, at: ExampleNFTContract.CollectionPublicPath)
    }

    execute {}
}
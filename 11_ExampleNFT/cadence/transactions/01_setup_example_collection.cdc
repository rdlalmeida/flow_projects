import "ExampleNFTContract"
import "NonFungibleToken"

transaction() {
    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {
        if (signer.storage.borrow<&{NonFungibleToken.Collection}>(from: ExampleNFTContract.CollectionStoragePath) != nil) {
            log(
                "Account "
                .concat(signer.address.toString())
                .concat(" already has a NonFungibleToken.Collection in storage!")
            )
            return
        }

        let collection: @{NonFungibleToken.Collection} <- ExampleNFTContract.createEmptyCollection(nftType: Type<@{NonFungibleToken.NFT}>())

        signer.storage.save(<- collection, to: ExampleNFTContract.CollectionStoragePath)

        let collectionCap: Capability<&{NonFungibleToken.Collection}> = signer.capabilities.storage.issue<&{NonFungibleToken.Collection}>(ExampleNFTContract.CollectionStoragePath)

        signer.capabilities.publish(collectionCap, at: ExampleNFTContract.CollectionPublicPath)
    }

    execute {}
}
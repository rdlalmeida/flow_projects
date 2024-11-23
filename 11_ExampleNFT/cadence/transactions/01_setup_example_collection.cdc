import "ExampleNFTContract"
import "NonFungibleToken"
import "FlowFees"

transaction() {
    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {
        let initialFeeBalance: UFix64 = FlowFees.getFeeBalance();
        
        log(
            "01-SetupCollection: Current Fee Balance = "
            .concat(initialFeeBalance.toString())
        )

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

        let lastFeeBalance = FlowFees.getFeeBalance();
        log(
            "01-SetupCollection: Final Fee Balance = "
            .concat(lastFeeBalance.toString())
        )
    }

    execute {}
}
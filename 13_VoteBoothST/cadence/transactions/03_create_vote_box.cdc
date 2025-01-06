import "VoteBoothST"
import "NonFungibleToken"

transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let randomResource: @AnyResource? <- signer.storage.load<@AnyResource>(from: VoteBoothST.voteBoxStoragePath)

        if (randomResource != nil) {
            log(
                "Warning: account "
                .concat(signer.address.toString())
                .concat(" already as an object from type '")
                .concat(randomResource.getType().identifier)
                .concat("' saved in ")
                .concat(VoteBoothST.voteBoxStoragePath.toString())
            )
        }

        destroy randomResource

        let oldCap: Capability? = signer.capabilities.unpublish(VoteBoothST.voteBoxPublicPath)

        if (oldCap != nil) {
            log(
                "Found a type '"
                .concat(oldCap.getType().identifier)
                .concat("' capability in ")
                .concat(VoteBoothST.voteBoxPublicPath.toString())
                .concat(" for account ")
                .concat(signer.address.toString())
            )
        }

        let newCollection: @{NonFungibleToken.Collection} <- VoteBoothST.createEmptyCollection(nftType: Type<@VoteBoothST.Ballot>())

        signer.storage.save<@{NonFungibleToken.Collection}>(<- newCollection, to: VoteBoothST.voteBoxStoragePath)

        let voteBoxCap: Capability<&{NonFungibleToken.Collection}> = signer.capabilities.storage.issue<&{NonFungibleToken.Collection}>(VoteBoothST.voteBoxStoragePath)

        signer.capabilities.publish(voteBoxCap, at: VoteBoothST.voteBoxPublicPath)
    }

    execute {

    }
}
import "VoteBooth_std"
import "NonFungibleToken"

transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Start by "cleaning up" the collection storage spot, just in case

        // Save the new collection into storage

        let randomResource: @AnyResource? <- signer.storage.load<@AnyResource>(from: VoteBooth_std.voteBoxStoragePath)

        if (randomResource != nil) {
            log(
                "Warning: account "
                .concat(signer.address.toString())
                .concat(" already as an object from type '")
                .concat(randomResource.getType().identifier)
                .concat("' saved in ")
                .concat(VoteBooth_std.voteBoxStoragePath.toString())
            )
        }

        // Destroy it anyways
        destroy randomResource

        // Unlink any existing capabilities before publishing new ones
        let result: Capability? = signer.capabilities.unpublish(VoteBooth_std.voteBoxPublicPath)
        
        if (result != nil) {
            log(
                "Found a type '"
                .concat(result.getType().identifier)
                .concat("' capability in ")
                .concat(VoteBooth_std.voteBoxPublicPath.toString())
                .concat(" for account ")
                .concat(signer.address.toString())
            )
        }

        let newCollection: @{NonFungibleToken.Collection} <- VoteBooth_std.createEmptyVoteBox()

        // Save it into storage
        signer.storage.save<@{NonFungibleToken.Collection}>(<- newCollection, to: VoteBooth_std.voteBoxStoragePath)

        let voteBoxCap: Capability<&{NonFungibleToken.Collection}> = signer.capabilities.storage.issue<&{NonFungibleToken.Collection}>(VoteBooth_std.voteBoxStoragePath)

        // And publish the public capability
        signer.capabilities.publish(voteBoxCap, at: VoteBooth_std.voteBoxPublicPath)
    }

    execute{

    }
}
import "VoteBoothST"
import "NonFungibleToken"

transaction() {
    let signerAddress: Address

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.signerAddress = signer.address

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

        let newVoteBox: @VoteBoothST.VoteBox <- VoteBoothST.createEmptyVoteBox()

        signer.storage.save<@VoteBoothST.VoteBox>(<- newVoteBox, to: VoteBoothST.voteBoxStoragePath)

        let voteBoxCap: Capability<&VoteBoothST.VoteBox> = signer.capabilities.storage.issue<&VoteBoothST.VoteBox>(VoteBoothST.voteBoxStoragePath)

        signer.capabilities.publish(voteBoxCap, at: VoteBoothST.voteBoxPublicPath)
    }

    execute {
        // Emit the corresponding event if all went OK
        VoteBoothST.emitVoteBoxCreated(voterAddress: self.signerAddress)
    }
}
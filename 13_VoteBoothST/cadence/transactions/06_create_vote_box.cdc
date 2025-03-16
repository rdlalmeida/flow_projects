import "VoteBoothST"

transaction() {
    let signerAddress: Address

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.signerAddress = signer.address

        let randomResource: @AnyResource? <- signer.storage.load<@AnyResource>(from: VoteBoothST.voteBoxStoragePath)

        if (randomResource != nil) {
            // Test if the resource retrieved is a VoteBox. If it is, panic and get out. I don't want this transaction to destroy any VoteBox, regardless if it contains a Ballot already
            if (randomResource.getType() == Type<@VoteBoothST.VoteBox>()) {
                panic(
                    "ERROR: Account "
                    .concat(signer.address.toString())
                    .concat(" already has a valid @VoteBoothST.VoteBox at ")
                    .concat(VoteBoothST.voteBoxStoragePath.toString())
                    .concat(". Cannot continue since this VoteBox may contain a valid Ballot!")
                )
            }

            // If I get here, the randomResource is something else than a VoteBox. Carry on
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
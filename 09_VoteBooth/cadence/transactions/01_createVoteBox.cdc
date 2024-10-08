import "VoteBooth_std"

transaction() {
    /*
        By signing this transaction, the user provides a reference to his/her account (the &Account object) with access to functions and parameters defined by the entitlements 'Storage' and 'Capabilities'. The entitlement 'Storage' contains the sub-entitlements 'SaveValue', 'LoadValue' and 'BorrowValue', which means that this transaction can do any of these three operations in the signer's storage. An easy way to protect against unwanted tefts is to protect the transaction restricting the entitlements to only 'SaveValue' and 'BorrowValue'. The 'Capabilities' entitlements allows this transaction to issue and publish capabilites (the old 'link' to a public path), which gives certain abilities to borrowed resources from the public path.
    */

    let voteBoxRef: &VoteBooth_std.VoteBox?

    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Check first if the signer already has a VoteBox Collection in the account.
        self.voteBoxRef = signer.storage.borrow<&VoteBooth_std.VoteBox>(from: VoteBooth_std.voteBoxStoragePath)

        // If the reference came back a nil, the voteBox does not exist yet
        if (self.voteBoxRef ==  nil) {
            signer.storage.save(<- VoteBooth_std.createEmptyVoteBox(), to: VoteBooth_std.voteBoxStoragePath)
        }

        // At this stage, I have a reference to a VoteBox in the signer's account
        // To allow others (including the VoteBooth_std contract) to deposit tokens into it, storage capabilities need to be published to a public path
        // TODO: Test that these capabilities do not allow others to load the tokens, and therefore modify/delete them
        let storageCapabilities: Capability<&VoteBooth_std.VoteBox> = signer.capabilities.storage.issue<&VoteBooth_std.VoteBox>(VoteBooth_std.voteBoxStoragePath)

        // Public these to the public path
        signer.capabilities.publish(storageCapabilities, at: VoteBooth_std.voteBoxPublicPath)
    }

    execute {
        // Nothing to do in this one
    }
}
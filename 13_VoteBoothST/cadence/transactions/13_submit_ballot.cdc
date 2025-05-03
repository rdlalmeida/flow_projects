import "VoteBoothST"

transaction() {
    let voteBoxRef: auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox

    prepare(signer: auth(Storage) &Account) {
        self.voteBoxRef = signer.storage.borrow<auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to get a valid auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )
    }

    execute {
        // All good. Submit the vote
        self.voteBoxRef.submitBallot()
    }
}
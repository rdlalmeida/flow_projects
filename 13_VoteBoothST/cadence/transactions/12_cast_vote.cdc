import "VoteBoothST"

transaction(vote: UInt8?) {
    let voteBoxRef: auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox

    prepare(signer: auth(Storage) &Account) {
        self.voteBoxRef = signer.storage.borrow<auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to get a valid auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox from "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )
    }

    execute {
        // Cast the vote but nothing more. The Ballot remains in the VoteBox
        self.voteBoxRef.castVote(option: vote)
    }
}
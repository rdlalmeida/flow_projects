import "VoteBoothST"

access(all) fun main(voterAddress: Address): Address? {
    let voteBoxRef: &VoteBoothST.VoteBox = getAccount(voterAddress).capabilities.borrow<&VoteBoothST.VoteBox>(VoteBoothST.voteBoxPublicPath) ??
    panic(
        "Unable to retrieve a valid &VoteBoothST.VoteBox at "
        .concat(VoteBoothST.voteBoxPublicPath.toString())
        .concat(" for account ")
        .concat(voterAddress.toString())
    )

    return voteBoxRef.getBallotOwner()
}
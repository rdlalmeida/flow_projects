import "VoteBoothST"

access(all) fun main(voterAddress: Address): Int? {
    // Get the account from the address provided
    let voterAccount: &Account = getAccount(voterAddress)
    
    let voteBoxRef: &VoteBoothST.VoteBox = voterAccount.capabilities.borrow<&VoteBoothST.VoteBox>(VoteBoothST.voteBoxPublicPath) ??
    panic(
        "Unable to get a valid &VoteBoothST.VoteBox at "
        .concat(VoteBoothST.voteBoxPublicPath.toString())
        .concat(" for account ")
        .concat(voterAddress.toString())
    )

    let currentVote: Int? = voteBoxRef.getCurrentVote()

    return currentVote
}
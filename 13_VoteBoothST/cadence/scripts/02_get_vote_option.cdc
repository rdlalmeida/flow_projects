import "VoteBoothST"
import "NonFungibleToken"


access(all) fun main(userAddress: Address, ballotId: UInt64): Int? {
    let userAccount: &Account = getAccount(userAddress)

    let voteBoxRef: &VoteBoothST.VoteBox = userAccount.capabilities.borrow<&VoteBoothST.VoteBox>(VoteBoothST.voteBoxPublicPath) ??
    panic(
        "Unable to get a &VoteBoothST.VoteBox at "
        .concat(VoteBoothST.voteBoxPublicPath.toString())
        .concat(" for account ")
        .concat(userAddress.toString())
    )

    return voteBoxRef.getCurrentVote()
}
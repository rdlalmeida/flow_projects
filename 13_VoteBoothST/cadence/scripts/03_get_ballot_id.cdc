import "VoteBoothST"
import "NonFungibleToken"

access(all) fun main(voter: Address): UInt64? {
    let voterAccount: &Account = getAccount(voter)

    let voteBoxRef: &VoteBoothST.VoteBox = voterAccount.capabilities.borrow<&VoteBoothST.VoteBox>(VoteBoothST.voteBoxPublicPath) ??
    panic(
        "Unable to retrieve a valid &VoteBoothST.VoteBox from account ".concat(voter.toString())
    )

    return voteBoxRef.getBallotId()
}
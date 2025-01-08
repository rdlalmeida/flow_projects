import "VoteBoothST"
import "NonFungibleToken"


access(all) fun main(userAddress: Address, ballotId: UInt64): UInt64? {
    let userAccount: &Account = getAccount(userAddress)

    let voteBoxRef: &VoteBoothST.VoteBox = userAccount.capabilities.borrow<&VoteBoothST.VoteBox>(VoteBoothST.voteBoxPublicPath) ??
    panic(
        "Unable to get a &VoteBoothST.VoteBox at "
        .concat(VoteBoothST.voteBoxPublicPath.toString())
        .concat(" for account ")
        .concat(userAddress.toString())
    )

    let nftRef: &{NonFungibleToken.NFT}? = voteBoxRef.borrowNFT(ballotId)

    if (nftRef == nil) {
        panic(
            "Unable to borrow a reference to a valid Ballot for account ".concat(userAddress.toString())
        )
    }

    let ballotRef: &VoteBoothST.Ballot = nftRef as! &VoteBoothST.Ballot

    return ballotRef.getVote()
}
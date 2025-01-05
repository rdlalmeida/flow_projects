import "VoteBooth_std"
import "NonFungibleToken"

/*
    NOTE: This script is for testing purposes solely. Otherwise this would be a MAJOR security breach! I'm allowing scripts to access Ballot options, which simply nullifies voter privacy! This point is actually a very thorny one. How to ensure that the owner and only the owner of the ballot can read it? I don't think there's a straight answer in Flow for that. My best option is to encrypt the option value and allow everyone to access it, but only the owner of the decryption key can actually check it.
    The biggest problem is that the function that returns the option is a NFT function, so one must have access to it to check it. From here, either I keep the token in storage and let Flow block adversaries from accessing this resource, or publish a capability a priori and use it to get access to the function
*/
access(all) fun main(userAddress: Address, ballotId: UInt64): UInt64? {
    let userAccount: &Account = getAccount(userAddress)

    // Get a reference to the account's VoteBox fist

    let voteBoxRef: &VoteBooth_std.VoteBox = userAccount.capabilities.borrow<&VoteBooth_std.VoteBox>(VoteBooth_std.voteBoxPublicPath) ??
    panic(
        "Unable to get a &VoteBooth_std.VoteBox at "
        .concat(VoteBooth_std.voteBoxPublicPath.toString())
        .concat(" for account ")
        .concat(userAddress.toString())
    )

    log("VoteBox reference: ")
    log(voteBoxRef)

    let nftRef: &{NonFungibleToken.NFT}? = voteBoxRef.borrowNFT(ballotId)

    log("NFT reference: ")
    log(nftRef)

    if (nftRef == nil) {
        panic(
            "Unable to borrow a reference to a valid Ballot for account "
            .concat(userAddress.toString())
        )
    }

    let ballotRef: &VoteBooth_std.Ballot = nftRef as! &VoteBooth_std.Ballot

    return ballotRef.getVote()
}
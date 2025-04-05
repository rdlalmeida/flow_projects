import "VoteBoothST"

access(all) fun main(deployerAddress: Address): Int {
    let deployerAccount: &Account = getAccount(deployerAddress)

    let burnBoxRef: &VoteBoothST.BurnBox = deployerAccount.capabilities.borrow<&VoteBoothST.BurnBox>(VoteBoothST.burnBoxPublicPath) ??
    panic(
        "Unable to get a valid &VoteBoothST.BurnBox at "
        .concat(VoteBoothST.burnBoxPublicPath.toString())
        .concat(" for account ")
        .concat(deployerAddress.toString())
    )

    return burnBoxRef.howManyBallotsToBurn()
}
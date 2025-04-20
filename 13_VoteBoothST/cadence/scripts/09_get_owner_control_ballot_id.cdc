import "VoteBoothST"

access(all) fun main(ownerControlAddress: Address, ballotOwner: Address): UInt64? {
    let deployerAccount: &Account = getAccount(ownerControlAddress)

    let ownerControlRef: &VoteBoothST.OwnerControl = deployerAccount.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
    panic(
        "Unable to get a valid &VoteBoothST.OwnerControl at "
        .concat(VoteBoothST.ownerControlPublicPath.toString())
        .concat(" for account ")
        .concat(ownerControlAddress.toString())
    )

    return ownerControlRef.getBallotId(owner: ballotOwner)
}
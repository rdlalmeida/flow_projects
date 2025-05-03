import "VoteBoothST"

access(all) fun main(ownerControlAddress: Address, ballotIdToGet: UInt64): Address? {
    let deployerAccount: &Account = getAccount(ownerControlAddress)

    let ownerControlRef: &VoteBoothST.OwnerControl = deployerAccount.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
    panic(
        "Unable to retrieve a valid &VoteBoothST.OwnerControl at "
        .concat(VoteBoothST.ownerControlPublicPath.toString())
        .concat(" for account ")
        .concat(ownerControlAddress.toString())
    )

    return ownerControlRef.getOwner(ballotId: ballotIdToGet)
}
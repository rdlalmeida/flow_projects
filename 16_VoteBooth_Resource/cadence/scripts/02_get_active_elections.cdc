/**
    Simple script to return an array with all the electionIds from active Elections in the given account provided as input argument.

    @param deployerAddress (Address) The address of the account that contains the ElectionIndex resource.
**/
import "VoteBooth"
import "ElectionStandard"

access(all) fun main(): [UInt64] {
    let deployerAccount: &Account = getAccount(VoteBooth.deployerAddress)

    let electionIndexRef: &{VoteBooth.ElectionIndexPublic} = deployerAccount.capabilities.borrow<&{VoteBooth.ElectionIndexPublic}>(VoteBooth.electionIndexPublicPath) ??
    panic(
        "Unable to retrieve a valid &{VoteBooth.ElectionIndexPublic} at "
        .concat(VoteBooth.electionIndexPublicPath.toString())
        .concat(" from account ")
        .concat(deployerAccount.address.toString())
    )

    return electionIndexRef.getActiveElectionIds()
}
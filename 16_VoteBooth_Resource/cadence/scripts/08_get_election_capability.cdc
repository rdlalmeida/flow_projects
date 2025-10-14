/**
    This script automates the retrieval of the public capability for the Election identified with the electionId provided, as set to be provided to issued Ballots.

    @param electionId: (UInt64) The election identifier for the Election resource whose parameter is to be returned to.

    @returns (Capability<&{ElectionStandard.ElectionPublic}>) Returns the capability associated to the Election, if it exists. Otherwise, the process panics at the offending step.
**/
import "VoteBooth"
import "ElectionStandard"

access(all) fun main(electionId: UInt64): Capability<&{ElectionStandard.ElectionPublic}> {
    let deployerAccount: &Account = getAccount(VoteBooth.deployerAddress)

    let electionIndexRef: &{VoteBooth.ElectionIndexPublic} = deployerAccount.capabilities.borrow<&{VoteBooth.ElectionIndexPublic}>(VoteBooth.electionIndexPublicPath) ??
    panic(
        "Unable to get a valid &{VoteBooth.ElectionIndexPublic} at "
        .concat(VoteBooth.electionIndexPublicPath.toString())
        .concat(" from account ")
        .concat(deployerAccount.address.toString())
    )

    let electionRef: &{ElectionStandard.ElectionPublic} = electionIndexRef.getPublicElectionReference(_electionId: electionId)!

    return electionRef.getElectionCapability() as! Capability<&{ElectionStandard.ElectionPublic}>
}
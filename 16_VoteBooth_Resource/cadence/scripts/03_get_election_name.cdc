/**
    This script automates the retrieval of the name for the Election identified with the electionId provided.

    @param electionId (UInt64) The election identifier for the Election resource whose parameter is to be returned to.

    @returns (String) Returns the name of the Election, if it exists. Otherwise, the process panics at the offending step.
**/

import "VoteBooth"
import "ElectionStandard"

access(all) fun main(electionId: UInt64): String {
    let deployerAccount: &Account = getAccount(VoteBooth.deployerAddress)

    let electionIndexRef: &{VoteBooth.ElectionIndexPublic} = deployerAccount.capabilities.borrow<&{VoteBooth.ElectionIndexPublic}>(VoteBooth.electionIndexPublicPath) ??
    panic(
        "Unable to get a valid &{VoteBooth.ElectionIndexPublic} at "
        .concat(VoteBooth.electionIndexPublicPath.toString())
        .concat(" from account ")
        .concat(deployerAccount.address.toString())
    )

    let electionRef: &{ElectionStandard.ElectionPublic} = electionIndexRef.getPublicElectionReference(_electionId: electionId)!

    return electionRef.getElectionName()
    
}
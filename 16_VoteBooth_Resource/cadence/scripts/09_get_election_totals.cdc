/**
    This script automates the retrieval of the ballot totals, minted and submitted, for the Election identified with the electionId provided.

    @param electionId: (UInt64) The election identifier for the Election resource whose parameter is to be returned to.

    @returns ({String: UInt}) Returns the ballot totals associated to the Election, if it exists, in a format using the original variable name as key, and the current total as value. Otherwise, the process panics at the offending step.
**/
import "VoteBooth"
import "ElectionStandard"

access(all) fun main(electionId: UInt64): {String: UInt} {
    let deployerAccount: &Account = getAccount(VoteBooth.deployerAddress)

    let electionIndexRef: &{VoteBooth.ElectionIndexPublic} = deployerAccount.capabilities.borrow<&{VoteBooth.ElectionIndexPublic}>(VoteBooth.electionIndexPublicPath) ??
    panic(
        "Unable to get a valid &{VoteBooth.ElectionIndexPublic} at "
        .concat(VoteBooth.electionIndexPublicPath.toString())
        .concat(" from account ")
        .concat(deployerAccount.address.toString())
    )

    let electionRef: &{ElectionStandard.ElectionPublic} = electionIndexRef.getPublicElectionReference(_electionId: electionId)!

    var ballotTotals: {String: UInt} = {}

    ballotTotals["totalBallotsMinted"] = electionRef.getTotalBallotsMinted()
    ballotTotals["totalBallotsSubmitted"] = electionRef.getTotalBallotsSubmitted()

    return ballotTotals
}
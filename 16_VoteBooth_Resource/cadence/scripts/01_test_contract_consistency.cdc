/**
    Script to test the contract consistency of all contracts in this project, namely:
    1. BallotStandard.cdc
    2. ElectionStandard.cdc
    3. VoteBoxStandard.cdc
    4. VoteBooth

    The logic is to check that each contract in that list apart from #1 was deployed into the same account.
**/
import "BallotStandard"
import "ElectionStandard"
import "VoteBoxStandard"
import "VoteBooth"

access(all) fun main(): Bool {
    let ballotDeployer: Address = BallotStandard.deployerAddress
    let electionDeployer: Address = ElectionStandard.deployerAddress
    let voteBoxDeployer: Address = VoteBoxStandard.deployerAddress
    let voteboothDeployer: Address = VoteBooth.deployerAddress

    if (electionDeployer == ballotDeployer) {
        log(
            "Election standard is consistent."
        )
    }
    else {
        log(
            "WARNING: BallotStandard(`ballotDeployer.toString()`) and ElectionStandard(`electionDeployer.toString()`) are deployed into different accounts!"
        )

        return false
    }

    if (voteBoxDeployer == electionDeployer) {
        log(
            "VoteBox standard is consistent."
        )
    }
    else {
        log(
            "WARNING: VoteBoxStandard(`voteBoxDeployer.toString()`) and ElectionStandard(`electionDeployer.toString()`) are deployed into different accounts!"
        )

        return false
    }

    if (voteboothDeployer == voteBoxDeployer) {
        log(
            "VoteBooth and the remaining standards are consistently deployed at `voteboothDeployer.toString()`"
        )
    }
    else {
        log(
            "WARNING: VoteBooth(`voteboothDeployer.toString()`) and VoteBoxStandard(`voteBoxDeployer.toString()`) are deployed into different accounts!"
        )

        return false
    }

    return true
}
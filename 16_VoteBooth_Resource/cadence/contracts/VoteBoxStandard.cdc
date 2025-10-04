/**
    ## The VoteBox Resource standard

    The interface that regulates the VoteBox resource and usage. VoteBoxes are resources that give to a voter their ability to interact with this application using the methods exposed by this resource. As it has been the case so far, I'm using Interfaces to establish standards for every resource implemented in this process.

    # Author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/
import "Burner"
import "BallotStandard"
import "ElectionStandard"

access(all) contract VoteBoxStandard {
    // CUSTOM ENTITLEMENTS
    access(all) entitlement VoteBoxAdmin

    // CUSTOM EVENTS
    // This event emits when a VoteBox is burned using the Burner contract. The idea is to reveal only the electionIds that this VoteBox has been used to 
    // submit Ballots (the _electionsVoted array), as well as the list of active Ballots, or better, the electionIds for the Elections that this VoteBox
    // has an active Ballot in it
    access(all) event VoteBoxDestroyed(_electionsVoted: [UInt64], _activeBallots: Int, _voterAddress: Address)

    // This event is emitted when the voter attempts to set an option, or cast a non-existent Ballot.
    access(all) event MissingElectionBallot(_electionId: UInt64)

    access(all) resource VoteBox: Burner.Burnable{
        access(self) let voteBoxId: UInt64

        // Internally, I want this VoteBox to store only one Ballot per Election. As such, I'm using the Ballot's electionId index as key for the
        // internal dictionary
        access(self) var storedBallots: @{UInt64: BallotStandard.Ballot}

        // This array stores all the electionIds for submitted Ballots, regardless of their outcome, i.e., even if a voter revokes their Ballot at a later
        // stage, the electionId of that Election is still stored here. This is merely a statistical parameter to provide feedback to the voter more than
        // anything. This array stored the electionId whenever a Ballot is submitted to a given Election.
        access(self) var electionsVoted: [UInt64]
        
        // VoteBox resource constructor
        init() {
            self.voteBoxId = self.uuid
            self.storedBallots <- {}
            self.electionsVoted = []
        }
    }

    // VoteBoxStandard contract constructor
    init() {}
}
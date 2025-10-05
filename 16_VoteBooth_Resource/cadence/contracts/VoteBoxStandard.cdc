/**
    ## The VoteBox Resource standard

    The interface that regulates the VoteBox resource and usage. VoteBoxes are resources that give to a voter their ability to interact with this application using the methods exposed by this resource. As it has been the case so far, I'm using Interfaces to establish standards for every resource implemented in this process.

    # Author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "Burner"
import "BallotStandard"
import "ElectionStandard"

access(all) contract VoteBoxStandard {
    // CUSTOM PATHS
    access(all) let voteBoxStoragePath: StoragePath
    access(all) let voteBoxPublicPath: PublicPath

    // CUSTOM ENTITLEMENTS
    access(all) entitlement VoteBoxAdmin

    // CUSTOM EVENTS
    // This event emits when a VoteBox is burned using the Burner contract. The idea is to reveal only the electionIds that this VoteBox has been used to 
    // submit Ballots (the _electionsVoted array), as well as the list of active Ballots, or better, the electionIds for the Elections that this VoteBox
    // has an active Ballot in it
    access(all) event VoteBoxDestroyed(_electionsVoted: [UInt64], _activeBallots: Int, _voterAddress: Address)
    
    access(all) resource VoteBox: Burner.Burnable {
        access(self) let voteBoxId: UInt64
        // Internally, I want this VoteBox to store only one Ballot per Election. As such, I'm using the Ballot's electionId index as key for the
        // internal dictionary
        access(self) var activeBallots: @{UInt64: BallotStandard.Ballot}

        // This array stores all the electionIds for submitted Ballots, regardless of their outcome, i.e., even if a voter revokes their Ballot at a later
        // stage, the electionId of that Election is still stored here. This is merely a statistical parameter to provide feedback to the voter more than
        // anything. This array stored the electionId whenever a Ballot is submitted to a given Election.
        access(self) var electionsVoted: [UInt64]

        /**
            Simple getter to retrieve the current option set. This is inoffensive since the String returned is the blinded ciphertext. The only information leaked is if the current Ballot was set or not.

            @param electionId (UInt64) The election identifier for the Ballot whose vote is to be retrieved.

            @returns String The current option set in the Ballot resource identified by the electionId provided. Returns nil if there no Ballot for the electionId supplied.
        **/
        access(BallotStandard.BallotAdmin) view fun getVote(electionId: UInt64): String? {
            let ballotRef: auth(BallotStandard.BallotAdmin) &BallotStandard.Ballot? = &self.activeBallots[electionId]

            if (ballotRef == nil) {
                return nil
            }
            else {
                return ballotRef!.getOption()
            }
        }

        /**
            Function to set the option field in a Ballot stored in this VoteBox. This function activates the one at Ballot.vote, which is protected with same entitlement as this one, for obvious consistency.
            NOTE: This function DOES NOT deliver the Ballot anywhere, it only changes the resource's option metadata parameter.

            @param electionId (UInt64) The Election identifier for the Ballot that is to be set to.
            @param newOption (String) The new option to set the Ballot to. The assumption is that this function is to be invoked from a frontend application that has blinded and encrypted the option already, so this String is supposed to be a ciphertext.
        **/
        access(BallotStandard.BallotAdmin) fun setOption(electionId: UInt64, newOption: String): Void {
            // This function does not does anything to the dictionary of active Ballots. Make sure that this situation is consistent
            pre {
                self.activeBallots[electionId] != nil: "There are no Ballots for election ".concat(electionId.toString()).concat(" currently in storage!")
            }
            post {
                self.activeBallots[electionId] != nil: "Missing the set Ballot for election ".concat(electionId.toString()).concat(" currently in storage!")
            }

            // Set the option of the Ballot in question without removing it from the internal dictionary
            let ballotRef: auth(BallotStandard.BallotAdmin) &BallotStandard.Ballot? = &self.activeBallots[electionId]

            // I've ensured with the pre-condition that the Ballot whose option I want to set exists, so I can force cast it safely
            ballotRef!.vote(newOption: newOption)

        }

        /**
            Function to deliver the Ballot to the Election resource whose reference is obtainable through the Ballot's electionCapability parameter. The electionId argument is used to retrieve the Ballot from internal storage. If there's none, the relevant event is emitted instead.

            @param electionId (UInt64) The Election identifier for the Ballot that is to be be cast.
        **/
        access(BallotStandard.BallotAdmin) fun castBallot(electionId: UInt64): Void {
            // Similar to the "setOption" function, this one checks initially if a Ballot with the provided electionId already exists before continuing
            pre {
                self.activeBallots[electionId] != nil: "There are no Ballot for election ".concat(electionId.toString()).concat(" currently in storage!")
            }

            // When this function finishes, there shouldn't be any Ballots under the provided electionId
            post {
                self.activeBallots[electionId] == nil: "Ballot ".concat(electionId.toString()).concat(" should have been submitted. Cannot continue!")
            }

            let ballotToSubmit: @BallotStandard.Ballot <- self.activeBallots.remove(key: electionId) ??
            panic(
                "Unable to retrieve a valid @BallotStandard.Ballot from the VoteBox from account "
                .concat(self.owner!.address.toString())
                .concat(" with electionId ")
                .concat(electionId.toString())
            )

            // Got a valid Ballot. Use its PublicElection reference electionCapability to get a reference to the Election to submit this thing to
            // TODO: Not sure if this shit works... an authorized reference to a public capability? Seems fishy... this needs testing ASAP
            let electionReference: auth(BallotStandard.BallotAdmin) &{ElectionStandard.ElectionPublic} = ballotToSubmit.electionCapability.borrow<auth(BallotStandard.BallotAdmin) &{ElectionStandard.ElectionPublic}>() ??
            panic(
                "Unable to retrieve a valid &{ElectionStandard.ElectionPublic} from the electionCapability from Ballot "
                .concat(ballotToSubmit.ballotId.toString())
                .concat(" with electionId ")
                .concat(electionId.toString())
            )

            // Use the reference to access the "submitBallot" function and send the Ballot to the Election where it belongs
            electionReference.submitBallot(ballot: <- ballotToSubmit)
        }



        // This function retrieves all active Ballots from the activeBallots dictionary and burns them one by one with the Burner contract so that the
        // respective burnCallback is called for each destroyed Ballot
        access(contract) fun burnCallback(): Void {
            let ballotKeys: [UInt64] = self.activeBallots.keys
            let ballotsBurned: Int = self.activeBallots.length

            for ballotKey in ballotKeys {
                let ballotToBurn: @BallotStandard.Ballot? <- self.activeBallots.remove(key: ballotKey)

                // Destroy every Ballot individually
                Burner.burn(<- ballotToBurn)
            }
        }

        // VoteBox resource constructor
        init() {
            self.voteBoxId = self.uuid
            self.activeBallots <- {}
            self.electionsVoted = []
        }
    }

    // Contract constructor
    init() {
        self.voteBoxStoragePath = /storage/voteBox
        self.voteBoxPublicPath = /public/voteBox
    }
}
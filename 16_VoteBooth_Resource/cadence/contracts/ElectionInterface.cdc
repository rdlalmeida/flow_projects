/**
    ## The Election Resource standard

    The interface that regulates the Election resource and usage.

    # Author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "Burner"
import "BallotInterface"

access(all) contract interface ElectionInterface {
    // CUSTOM ENTITLEMENTS
    access(all) entitlement ElectionAdmin

    // CUSTOM EVENTS
    // Emit this one when a new Ballot gets deposited
    access(all) event BallotSubmitted(_ballotId: UInt64, _electionId: UInt64)

    // This one is for whenever an existing Ballot is replaced by another one
    access(all) event BallotModified(_ballotId: UInt64, _electionId: UInt64)

    // Event to emit when a Ballot is revoked, i.e., when an existing Ballot is revoked
    access(all) event BallotRevoked(_ballotId: UInt64, _electionId: UInt64)

    // Event for when all Ballots are withdrawn to be counted
    access(all) event BallotsWithdrawn(_ballotsWithdrawn: UInt, _electionId: UInt64)

    // The one event to emit when an Election resource is destroyed
    access(all) event ElectionDestroyed(_electionId: UInt64, _ballotsStored: UInt)

    // Standard event to emit when a resource of an unexpected type is obtained at some point
    access(all) event NonNilResourceReturned(_resourceType: Type)

    access(all) resource interface Election: Burner.Burnable {
        access(contract) let electionId: UInt64
        access(contract) let name: String
        access(contract) let ballot: String
        // The option dictionary is used to provide the options that are available to each voter. The idea is to use this one
        // to display the options to the user in the frontend application. The vote in itself is going to be the numeric
        // value used as key.
        access(contract) let options: {UInt8: String}

        // This parameter stores the public encryption to distribute to the voters through Ballots
        // The voter's frontend uses this key to encrypt the selected option on the Ballot before submitting it
        // The private counterpart of this key remains secured with the Election Administration, to be used during
        // the counting process
        access(all) let publicKey: String

        // Use these parameters to keep track of how many Ballots were printed and submitted for this particular Election instance
        // I set these as "access(ElectionAdmin)" because I want my BallotPrinterAdmin resource to operate on them and no one else.
        access(ElectionAdmin) var totalBallotsMinted: UInt
        access(ElectionAdmin) var totalBallotsSubmitted: UInt

        // The main structure to store the Ballots in this resource. Ballots are stored using a key that is derived from the voters
        // personal information, but anonymized through an hash digest or something of the sort. For now, keep it as a String to
        // maintain flexibility
        access(contract) var storedBallots: @{String: {BallotInterface.Ballot}}

        // Set of simple Getters for the Election parameters
        access(all) view fun getElectionName(): String {
            return self.name
        }

        access(all) view fun getElectionBallot(): String {
            return self.ballot
        }

        access(all) view fun getElectionOptions(): {UInt8: String} {
            return self.options
        }

        access(all) view fun getElectionId(): UInt64 {
            return self.electionId
        }

        access(all) view fun getPublicEncryptionKey(): String {
            return self.publicKey
        }

        // Set of functions to manipulate the total ballot counters
        access(all) fun increaseBallotsMinted(ballots: UInt): Void {
            self.totalBallotsMinted = self.totalBallotsMinted + ballots
        }

        access(all) fun incrementBallotsSubmitted(ballots: UInt): Void {
            self.totalBallotsSubmitted = self.totalBallotsSubmitted + ballots
        }

        access(all) fun decreaseBallotsMinted(ballots: UInt): Void {
            // I'm panicking if the totals are to go bellow 0 instead of just setting the total to 0 since this may
            // be the symptom of some bad math going on somewhere in the contract. If all goes well, this panic
            // should never be raised.
            if (ballots > self.totalBallotsMinted) {
                panic(
                    "Unable to decrease the total Ballots minted! Cannot decrease a total of "
                    .concat(self.totalBallotsMinted.toString())
                    .concat(" minted Ballots by ")
                    .concat(ballots.toString())
                    .concat(" without triggering an underflow error!")
                )
            }

            self.totalBallotsMinted = self.totalBallotsMinted - ballots
        }

        access(all) fun decreaseBallotsSubmitted(ballots: UInt): Void {
            if (ballots > self.totalBallotsSubmitted) {
                panic(
                    "Unable to decrease the Ballots submitted! Cannot decrease a total of "
                    .concat(self.totalBallotsSubmitted.toString())
                    .concat(" submitted Ballots by ")
                    .concat(ballots.toString())
                    .concat(" without triggering an underflow error!")
                )
            }

            self.totalBallotsSubmitted = self.totalBallotsSubmitted - ballots
        }

        /** 
            Main function that voters use to deliver their Ballots. The function receives a Ballot resource
            as input argument. The Ballot has, in itself, the key that is to be used to store the Ballot
            internally.

            @param: ballot (@{BallotStandard.Ballot} The Ballot to be submitted to this Election instance)
        **/
    }
}
/**
    ## The Election Resource standard

    The interface that regulates the Election resource and usage.

    # Author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "Burner"
import "BallotStandard"

access(all) contract ElectionStandard {
    // CUSTOM ENTITLEMENTS
    access(all) entitlement ElectionAdmin

    // CUSTOM EVENTS
    // Emit this one when a new Ballot gets deposited
    access(all) event BallotSubmitted(_ballotId: UInt64, _electionId: UInt64)

    // This one is for whenever an existing Ballot is replaced by another one
    access(all) event BallotReplaced(_oldBallotId: UInt64, _newBallotId: UInt64, _electionId: UInt64)

    // Event to emit when a Ballot is revoked, i.e., when an existing Ballot is revoked
    access(all) event BallotRevoked(_ballotId: UInt64, _electionId: UInt64)

    // Event for when all Ballots are withdrawn to be counted
    access(all) event BallotsWithdrawn(_ballotsWithdrawn: UInt, _electionId: UInt64)

    // The one event to emit when an Election resource is destroyed
    access(all) event ElectionDestroyed(_electionId: UInt64, _ballotsStored: UInt)

    // Standard event to emit when a resource of an unexpected type is obtained at some point
    access(all) event NonNilResourceReturned(_resourceType: Type)

    // This interface is used to expose the public version of the Election resource, i.e., which parameters and functions are available
    // to a third party user.
    access(all) resource interface ElectionPublic {
        access(contract) let publicKey: String
        access(all) let electionStoragePath: StoragePath
        access(all) let electionPublicPath: PublicPath
        
        access(all) view fun getElectionName(): String
        access(all) view fun getElectionBallot(): String
        access(all) view fun getElectionOptions(): {UInt8: String}
        access(all) view fun getElectionId(): UInt64
        access(all) view fun getPublicEncryptionKey(): String
        access(all) view fun getTotalBallotsMinted(): UInt
        access(all) view fun getTotalBallotsSubmitted(): UInt
        access(all) fun submitBallot(ballot: @BallotStandard.Ballot): Void
    }

    access(all) resource Election: Burner.Burnable, ElectionPublic {
        access(all) let electionStoragePath: StoragePath
        access(all) let electionPublicPath: PublicPath
        
        access(self) let electionId: UInt64
        access(self) let name: String
        access(self) let ballot: String
        // The option dictionary is used to provide the options that are available to each voter. The idea is to use this one
        // to display the options to the user in the frontend application. The vote in itself is going to be the numeric
        // value used as key.
        access(self) let options: {UInt8: String}

        // This parameter stores the public encryption to distribute to the voters through Ballots
        // The voter's frontend uses this key to encrypt the selected option on the Ballot before submitting it
        // The private counterpart of this key remains secured with the Election Administration, to be used during
        // the counting process
        access(contract) let publicKey: String

        // Use these parameters to keep track of how many Ballots were printed and submitted for this particular Election instance
        // I set these as "access(ElectionAdmin)" because I want my BallotPrinterAdmin resource to operate on them and no one else.
        access(ElectionAdmin) var totalBallotsMinted: UInt
        access(ElectionAdmin) var totalBallotsSubmitted: UInt

        // The main structure to store the Ballots in this resource. Ballots are stored using a key that is derived from the voters
        // personal information, but anonymized through an hash digest or something of the sort. For now, keep it as a String to
        // maintain flexibility
        access(self) var storedBallots: @{String: BallotStandard.Ballot}
        // This array is used by the Election Administrator to store the ballotId of every Ballot
        // issued to be used in this particular Election. If a Ballot submitted is not in this list,
        // it cannot be accepted. If the Ballot is submitted successfully, remove it from this list
        access(ElectionAdmin) var mintedBallots: [UInt64]

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

        access(all) view fun getTotalBallotsMinted(): UInt {
            return self.totalBallotsMinted
        }

        access(all) view fun getTotalBallotsSubmitted(): UInt {
            return self.totalBallotsSubmitted
        }

        // Set of functions to manipulate the total ballot counters
        access(all) fun increaseBallotsMinted(ballots: UInt): Void {
            self.totalBallotsMinted = self.totalBallotsMinted + ballots
        }

        access(all) fun increaseBallotsSubmitted(ballots: UInt): Void {
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

        // I need a getter and setter for the internal mintedBallots array
        // Use this one to check if the Ballot in question was minted to this Election or not
        access(ElectionAdmin) view fun isBallotMinted(ballotId: UInt64): Bool {
            return self.mintedBallots.contains(ballotId)
        }

        // This one is adapted from the "isBallotMinted" function that returns the ballotId if it
        // exists, or nil if it does not. But this function removes the item from the array to
        // return it, so it is a destructive function to an extend
        access(ElectionAdmin) fun getMintedBallot(ballotId: UInt64): UInt64? {
            let ballotIndex: Int? = self.mintedBallots.firstIndex(of: ballotId)

            // If I got a non-nil index, the ballotId is in the array
            if (ballotIndex != nil) {
                // Remove and return the ballotId in question
                let ballotIdToReturn: UInt64 = self.mintedBallots.remove(at: ballotIndex!)

                if (ballotIdToReturn != ballotId) {
                    panic(
                        "ERROR: Retrieved ballotId #"
                        .concat(ballotIdToReturn.toString())
                        .concat(" from mintedBallots at index ")
                        .concat(ballotIndex!.toString())
                        .concat(" but expected ballotId #")
                        .concat(ballotId.toString())
                        .concat(". Cannot continue!")
                    )
                }

                return self.mintedBallots.remove(at: ballotIndex!)
            }

            // Otherwise return nil
            return nil
        }

        // And this one to add a new item to the array. If by any reason that item is already there, this function panics instead
        access(ElectionAdmin) fun addMintedBallot(ballotId: UInt64): Void {
            if (self.mintedBallots.contains(ballotId)) {
                panic(
                    "ERROR: ballotId #"
                    .concat(ballotId.toString())
                    .concat(" already exists in the internal mintedBallots array. Cannot continue!")
                )
            }

            self.mintedBallots.append(ballotId)
        }

        /** 
            Main function that voters use to deliver their Ballots. The function receives a Ballot resource
            as input argument. The Ballot has, in itself, the key that is to be used to store the Ballot
            internally.

            NOTE: The assumption here is that only the owner of a Ballot with a proper configured capability to this
            particular Election resource, that exposed this and only this function, I have an assurance from
            the strong typed nature of Cadence that there is no other way to

            @param: ballot (@{BallotStandard.Ballot} The Ballot to be submitted to this Election instance)
        **/
        access(all) fun submitBallot(ballot: @BallotStandard.Ballot): Void {
            pre {
                // Check if the Ballot submitted was minted into this Election first. The BallotPrinterAdmin should have done that
                self.mintedBallots.contains(ballot.ballotId): "The Ballot submitted was not minted for this Election!"
            }

            // Store the ballotId from the Ballot to store for Event emission purposes
            let newBallotId: UInt64 = ballot.ballotId
            let newBallotIndex: String = ballot.ballotIndex

            // Check if the index where this Ballot is to be set has anything in it already
            let randomResourceRef: &AnyResource? = &self.storedBallots[newBallotIndex]

            /** 
                There are three possible scenarios from this point onwards:

                1. randomResourceRef == nil, i.e., There's nothing in that slot. This is the simplest and easiest scenario to deal with. In this case simply remove the ballotId from the list of mintedBallots and set this Ballot into the position defined by its ballotIndex parameter

                2. randomResourceRef == &{BallotInterface.Ballot}, i.e., there's a valid Ballot already set in this position, which means that this one is a
                re-vote one. In this case, remove the ballotId from the list of mintedBallots, grab and burn the old Ballot and replace it by this new one. This
                scenario is an expectable one as well, but not in the same frequency as #1.

                3. randomResourceRef == &SomethingElse, i.e., something was in that index position but it was not a valid Ballot. This scenario should never be encountered, so if it does happen, panic and stop this process immediately. Retrieve and use the type of the mystery resource in the panic message.
            **/
            if (randomResourceRef == nil) {
                // Set the Ballot in the proper spot
                let nilResource: @AnyResource? <- self.storedBallots[newBallotIndex] <- ballot

                // This variable is a nil, but due to Cadence strick rules, it still needs to be destroyed for consistency
                destroy nilResource

                // Increment the number of submitted Ballots in this Election
                self.increaseBallotsSubmitted(ballots: 1)

                // Finish by emitting the proper event
                emit BallotSubmitted(_ballotId: newBallotId, _electionId: self.electionId)
            }
            else if (randomResourceRef.getType() == Type<&BallotStandard.Ballot?>()) {
                // Grab the oldBallotId from the reference. I need to downcast it first, but I've ensured that I can only get in this branch if the type
                // of the reference matches the expected one, therefore I can do this downcast without problems.
                let oldBallotId: UInt64 = (randomResourceRef as! &BallotStandard.Ballot).ballotId

                // Replace the old Ballot with the new one
                let oldBallot: @BallotStandard.Ballot? <- self.storedBallots[newBallotIndex] <- ballot

                // I had to set the oldBallot retrieval as an optional, again, because Cadence is so picky. Irrelevant since I'm going to destroy it
                destroy oldBallot

                // No need to adjust the total Ballot submitted because I'm replacing a Ballot for another one
                // Finish with the respective event emission
                emit BallotReplaced(_oldBallotId: oldBallotId, _newBallotId: newBallotId, _electionId: self.electionId)
            }
            else {
                // In this case, emit the NonNilResourceReturned with the type of the resource retrieved, but continue with the normal submission
                let nonNilResource: @AnyResource <- self.storedBallots.remove(key: newBallotIndex)

                emit NonNilResourceReturned(_resourceType: nonNilResource.getType())
                destroy nonNilResource

                // The rest of this process is the one from 1.
                let nilResource: @AnyResource? <- self.storedBallots[newBallotIndex] <- ballot
                destroy nilResource

                self.increaseBallotsSubmitted(ballots: 1)
            }

            // Remove this ballotId from the list of mintedBallot. This is independent from the branch executed above
            let ballotId: UInt64 = self.mintedBallots.remove(at: newBallotId)
        }

        /**
            This function is used by the Election Authority to retrieve all Ballots in storage, but completely anonymized, since these are returned as an unordered array of the values from the internal storedBallots dictionary.

            @return: @[BallotInterface.Ballot] Returns an array with all the Ballots in no specific order, as stipulated by the Cadence documentation.
        **/
        access(ElectionAdmin) fun withdrawBallots(): @[BallotStandard.Ballot] {
            // Cadence is super picky when dealing with resources. There is no direct way to retrieve all the values from a dictionary as an array, for example, if these values are resources. As such, I need to do this "manually", i.e., one by one
            var ballotsToTally: @[BallotStandard.Ballot] <- []

            // Since the keys in the storedBallots are simple strings, I can get these all at once
            let ballotIndexes: [String] = self.storedBallots.keys

            for ballotIndex in ballotIndexes {
                let currentBallot: @BallotStandard.Ballot <- self.storedBallots.remove(key: ballotIndex)!

                // Append it to the return array
                ballotsToTally.append(<- currentBallot)
            }

            // Emit the proper event before returning the return array
            emit BallotsWithdrawn(_ballotsWithdrawn: UInt(ballotsToTally.length), _electionId: self.electionId)

            return <- ballotsToTally
        }

        /**
            Callback function to be executed when one of these Elections gets destroyed using the Burned contract
        **/
        access(contract) fun burnCallback(): Void {
            /**
                According to the Cadence documentation, triggering the burnCallback function on a collection, such is the case of Elections, it DOES NOT trigger a cascading execution of the inner resource's burnCallback functions. In other words, to trigger the Ballot's burnCallback function I need to destroy each individually using the Burner.Burn function
            **/
            let storedBallotsIndexes: [String] = self.storedBallots.keys

            let totalBallotsStored: UInt = UInt(self.storedBallots.length)

            for storedBallotIndex in storedBallotsIndexes {
                let ballotToBurn: @BallotStandard.Ballot? <- self.storedBallots.remove(key: storedBallotIndex)

                // Destroy it using the Burner contract
                Burner.burn(<- ballotToBurn)
            }

            // Emit the respective event before finishing
            emit ElectionDestroyed(_electionId: self.electionId, _ballotsStored: totalBallotsStored)
        }
        // Election Resource Constructor
        init(
            _electionName: String,
            _electionBallot: String,
            _electionOptions: {UInt8: String},
            _publicKey: String,
            _electionStoragePath: StoragePath,
            _electionPublicPath: PublicPath
        ) {
            self.electionId = self.uuid
            self.name = _electionName
            self.ballot = _electionBallot
            self.options = _electionOptions
            self.publicKey = _publicKey
            self.electionStoragePath = _electionStoragePath
            self.electionPublicPath = _electionPublicPath

            self.totalBallotsMinted = 0
            self.totalBallotsSubmitted = 0

            self.storedBallots <- {}
            self.mintedBallots = []
        }
    }

    // ElectionStandard contract constructor
    init() {

    }
}
/**
    ## The Election Resource standard

    This interface regulates the Election resource construction and usage. Election Resources are used to establish election exercises, which are characterized by:

    * The name of the Election
    * The ballot text, i.e., what the voters are supposed to vote for
    * The options available, as an UInt8 array

    NOTE: The idea is to have this resource interacting with a front end that builds and runs the transactions needed to work with this resource, the selection of the UInt8 to use to cast the vote is abstracted by this layer. From the voter point of view, he/she selects an option from a set in a screen and the programming layers translates the option selected to the UInt8 in question. It is far easier to work with a numerical array than with an array of Strings or a dictionary.

    # Author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "Burner"
import "BallotStandard"

access(all) contract interface ElectionStandard {
    // CUSTOM PATHS
    access(all) let burnBoxStoragePath: StoragePath
    access(all) let burnBoxPublicPath: PublicPath

    // CUSTOM ENTITLEMENTS
    access(all) entitlement ElectionAdmin

    // CUSTOM EVENTS
    // Event for when a Ballot is successfully submitted for tally
    access(all) event BallotSubmitted(_ballotId: UInt64, _electionId: UInt64)

    // Event for when a Ballot is replaced by another Ballot with a different option (or not. It's pointless by it is possible for a voter to re-submit a Ballot with the same option as before). The event indicates which Ballot was replaced and which one replaced it.
    access(all) event BallotModified(_oldBallotId: UInt64, _newBallotId: UInt64, _electionId: UInt64)

    // Event for when a Ballot is revoked.
    access(all) event BallotRevoked(_ballotId: UInt64, _electionId: UInt64)

    // Event for when some other resource other than a BallotStandard.Ballot is retrieved
    access(all) event NonNilResourceReturned(_resourceType: Type)

    // Event to inform users of how many Ballots were sent to be tallies, for a given election
    access(all) event BallotsWithdrawn(_ballots: UInt, _electionId: UInt64)

    // Event to emit when one of these Election resources gets destroyed using the Burner contract
    access(all) event ElectionDestroyed(_electionId: UInt64, _ballotsSubmitted: UInt)

    access(all) resource interface Election: Burner.Burnable {
        // Characterizing parameter for the Election resource
        access(contract) let electionId: UInt64
        access(all) let _name: String
        access(all) let _ballot: String
        access(all) let _options: [UInt8]

        // Parameters used to keep track of the Ballots minted and submitted for a particular election
        access(contract) var totalBallotsMinted: UInt
        access(contract) var totalBallotsSubmitted: UInt

        // The default ballot option, useful to determine the purpose of a Ballot submitted to this election. A Ballot with the default option set is considered a revoke Ballot
        access(all) let _defaultBallotOption: UInt8?

        // Main structure to store submitted Ballots
        access(contract) var submittedBallots: @{Address: {BallotStandard.Ballot}}

        // Getters for the election parameters
        access(all) view fun getElectionName(): String {
            return self._name
        }

        access(all) view fun getElectionBallot(): String {
            return self._ballot
        }

        access(all) view fun getElectionOptions(): [UInt8] {
            return self._options
        }

        access(all) view fun getElectionId(): UInt64 {
            return self.electionId
        }

        // Getters and setters for the ballot totals
        access(all) view fun getTotalBallotsMinted(): UInt {
            return self.totalBallotsMinted
        }

        access(all) view fun getTotalBallotsSubmitted(): UInt {
            return self.totalBallotsSubmitted
        }

        access(all) fun incrementTotalBallotsMinted(ballots: UInt): Void {
            self.totalBallotsMinted = self.totalBallotsMinted + ballots
        }

        access(all) fun incrementTotalBallotsSubmitted(ballots: UInt): Void {
            self.totalBallotsSubmitted = self.totalBallotsSubmitted + ballots
        }

        access(all) fun decrementTotalBallotsMinted(ballots: UInt): Void {
            // I'm using unsigned integers to represent these totals, which means that any subtraction that brings this value to < 0 throws an underflow error. Nevertheless, I'm doing a check and raising my own error (panic) just to have a more obvious error message than the underflow one.
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

        access(all) fun decrementTotalBallotsSubmitted(ballots: UInt): Void {
            if (ballots > self.totalBallotsSubmitted) {
                panic(
                    "Unable to decrease the total Ballots submitted! Cannot decrease a total of "
                    .concat(self.totalBallotsSubmitted.toString())
                    .concat(" minted Ballots by ")
                    .concat(ballots.toString())
                    .concat(" without triggering an underflow error!")
                )
            }

            self.totalBallotsSubmitted = self.totalBallotsSubmitted - ballots
        }

        /**
            This function submits a Ballot provided as argument into the internal Election storage. This Ballot, if valid, is anonymised (ballotOwner parameter set to nil) and stored in an Address -> Ballot dictionary. So, there's a tenuous (but private) link between a submitted Ballot and the user that submitted it, but it is not able to be accessed (let alone modified) by an unauthorized party. Why? Because this dictionary is 'access(contract)', therefore only the Election resource itself, and other contract methods, can access this dictionary. Once submitted, a Ballot is either sent to a TallyBox for counting (still in its anonymised version) or can be removed if the original voter submits a revoke Ballot (a Ballot with the defaultBallotOption set). Also, if the user/voter changes his/her mind and wants to change their opinion, they can simply submit another Ballot with a new option selected. Since I'm storing only one Ballot per Address, any Ballots submitted after the first one replaces any older one.

            @param: ballot (@{BallotStandard.Ballot} The Ballot to be submitted to this Election instance)
        **/
        access(all) fun submitBallot(ballot: @{BallotStandard.Ballot}): Void {
            pre{
                ballot.ballotOwner != nil: "Anonymous Ballot provided! The Ballot submitted is not registered to a valid address!"
                ballot.electionId == self.electionId: "The Ballot provided was registered to Election '".concat(ballot.electionId.toString()).concat(" but this Election has id '").concat(self.electionId.toString()).concat("'. Please submit the right Ballot or chose the right Election!")
            }

            // Store references to the values set in the Ballot since this is going to be anonymized in a bit
            let newBallotId: UInt64 = ballot.ballotId
            let newOwner: Address = ballot.ballotOwner!

            // Grab a reference to whatever is set in the internal dictionary for the position indicated by the ballotOwner
            let randomResourceRef: &AnyResource? = &self.submittedBallots[newOwner]

            // Anonymise the Ballot before moving forward
            ballot.anonymizeBallot()

            // Test the reference obtained above and proceed accordingly
            if (randomResourceRef == nil) {
                // This is the initial case for every first submission: there are no Ballots in storage at the ballotOwner spot yet
                if (ballot.isRevoked()) {
                    // If the Ballot is a revoke, there's not a lot to do since there's no other Ballot in storage in that position. As such, burn the Ballot provided
                    Burner.burn(<- ballot)

                    // Decrement the total number of ballots minted because of the last burn
                    self.decrementTotalBallotsMinted(ballots: 1)

                    // Emit the BallotRevoked event but the parameters from the Ballot just burned
                    emit BallotRevoked(_ballotId: newBallotId, _electionId: self.electionId)
                }
                else {
                    // Otherwise, it's a normal submission. 
                    let randomResource: @AnyResource? <- self.submittedBallots[newOwner] <- ballot

                    // Cadence is super type specific and super picky when it comes to store resources (and rightfully so!), which requires me to retrieve this randomResource, event though I've "proved" that there's nothing (nil) in that position. The cost of this is minimal, so move on
                    destroy randomResource

                    // Emit the respective Event
                    emit BallotSubmitted(_ballotId: newBallotId, _electionId: self.electionId)

                    // Increase the total number of Ballots submitted to this Election
                    self.incrementTotalBallotsSubmitted(ballots: 1)
                }
            }
            // TODO: Make sure the next 'else if' is properly tested to ensure the type is correct
            else if (randomResourceRef.getType() == Type<&{BallotStandard.Ballot}?>()) {
                // In this case, there's an older Ballot in this position. This is either a revoke or a re-submission. Test it and act accordingly
                // Start by removing the old Ballot from storage
                let oldBallot: @{BallotStandard.Ballot} <- self.submittedBallots.remove(key: newOwner) as! @{BallotStandard.Ballot}

                // Grab the old Ballot info to throw an Event later on
                let oldBallotId: UInt64 = oldBallot.ballotId

                // The owner of the oldBallot is no longer in the Ballot itself because it got anonymised before being stored. But the one constant in this function is the owner itself, so I can simply reutilize this parameter an move on.
                let oldOwner: Address = newOwner

                // Destroy the old Ballot and store the new one in its place. Use the Burner for this to run the burnCallback in the Ballot resource
                Burner.burn(<- oldBallot)

                // Anytime a Ballot gets burned, I need to decrement the ballot totals. For now, by burning the old Ballot, all I can guarantee at the moment is that the total minted needs to be decremented by 1
                self.decrementTotalBallotsMinted(ballots: 1)

                // Check if the new Ballot is a revoke one
                if (ballot.isRevoked()) {
                    // This means that the storage slot is to remain empty. Therefore proceed with burning the new Ballot as well
                    Burner.burn(<- ballot)

                    // Emit the BallotRevoked event but with the data from the oldBallot, since it was the one that got revoked after all
                    emit BallotRevoked(_ballotId: oldBallotId, _electionId: self.electionId)

                    // Decrement the total Ballots minted due to another Ballot getting burned
                    self.decrementTotalBallotsMinted(ballots: 1)

                    // But also the total submitted because there was no Ballot replacing the old one, which had been counted into the totals submitted before
                    self.decrementTotalBallotsSubmitted(ballots: 1)
                }
                else {
                    // Otherwise, this is a re-submission. I still need to destroy the oldBallot (which I already did) but now I need to put the new one in its place
                    let nilResource: @AnyResource? <- self.submittedBallots[newOwner] <- ballot

                    // This nil resource is nothing but a nil, but it still needs to be destroyed because Cadence is picky as hell in this regard. This is not a complaint. After all, it's all this pickiness that makes this whole thing work in the first place!
                    destroy nilResource

                    // Emit the BallotModified event with the details of the Ballots, which are still available
                    emit BallotModified(_oldBallotId: oldBallotId, _newBallotId: newBallotId, _electionId: self.electionId)
                    
                    // There's no need to adjust any Ballot totals at this point. All totals are consistent at this moment.
                }
            }
            else {
                // There is one last scenario that is highly unlikely, impossible even in this kind of platform, but as the good programmer I believe I am, I'm not going to be able to sleep peacefully without taking care of it regardless. There's a very, very small probability of having something else that is not a Ballot, nor a nil, in the ballotSubmitted position. Deal with it
                // Start by grabbing the mysterious resource from storage, emitting the respective event and destroying it
                let nonNilResource: @AnyResource <- self.submittedBallots.remove(key: newOwner)

                // I have a custom event just for these cases
                emit NonNilResourceReturned(_resourceType: nonNilResource.getType())

                // But there's not a lot to do after. Destroy the non nil resource
                destroy nonNilResource
                if (ballot.isRevoked()) {
                    // Burn the revoke Ballot
                    Burner.burn(<- ballot)

                    // Emit the BallotRevoked event but with the ballotId set to nil because this has not revoked any Ballots
                    emit BallotRevoked(_ballotId: newBallotId, _electionId: self.electionId)

                    // Adjust the totals by decrementing the total Ballots minted to account for the burned Ballot above
                    self.decrementTotalBallotsMinted(ballots: 1)
                }
                else {
                    // In this case, set the new Ballot to the position just freed by the mysterious resource
                    let nilResource: @AnyResource? <- self.submittedBallots[newOwner] <- ballot

                    // Destroy the nilResource because I'm 100% sure that it is a simple nil
                    destroy nilResource

                    // Emit the BallotSubmitted event
                    emit BallotSubmitted(_ballotId: newBallotId, _electionId: self.electionId)

                    // Increment the total Ballots submitted because of the new Ballot above
                    self.incrementTotalBallotsSubmitted(ballots: 1)
                }
            }
        }

        /**
            This function removes the Ballots in storage in an even more anonymised fashion, thus increasing the level of voter privacy. Right now, the only link between a submitted Ballot and the voter that casted it is the address used as key for the submittedBallots internal dictionary. This function simply returns the values of such dictionary in an array, in a semi randomised fashion.
            Due to the sensitive nature of this function, it can only be invoked with a TallyAdmin entitlement, which requires a borrow from storage, which implies that only this contract deployer can use it. Gotta love how simple and secure these things have become!

            @return: @[BallotStandard.Ballot] Returns an array with all the Ballots in no specific order, as stipulated in the Cadence documentation. The expectation is that this is going to build upon the voter privacy principles enacted thus far.
        **/
        access(BallotStandard.TallyAdmin) fun withdrawBallots(): @[{BallotStandard.Ballot}] {
            // Because I have a bunch of resources as values in an internal dictionary, Cadence does not allows me to simply do a "return <- self.submittedBallots.values" willy nilly. I need to "manually" extract each Ballot into an array to be able to return them.
            var ballotsToTally: @[{BallotStandard.Ballot}] <- []

            // I need to do this in a loop
            let storageAddresses: [Address] = self.submittedBallots.keys

            for storageAddress in storageAddresses {
                let currentBallot: @{BallotStandard.Ballot} <- self.submittedBallots.remove(key: storageAddress)!

                // Validate that the Ballot is properly anonymised
                if (currentBallot.ballotOwner != nil) {
                    panic(
                        "ERROR: Unable to tally Ballots! Ballot with id "
                        .concat(currentBallot.ballotId.toString())
                        .concat(" is not properly anonymised (ballotOwner is not a nil yet)")
                    )
                }

                // If the Ballot is anonymous, send it to the return array
                ballotsToTally.append(<- currentBallot)
            }

            // Emit the event with the total Ballots to return
            emit BallotsWithdrawn(_ballots: UInt(ballotsToTally.length), _electionId: self.electionId)

            // Return the array with all the Ballots to be tallied
            return <- ballotsToTally
        }

        /**
            Simple function to return the number of submitted Ballots currently in storage.

            @return: Int The number of entries in the self.submittedBallots dictionary
        **/
        access(all) view fun getSubmittedBallotCount(): Int {
            return self.submittedBallots.length
        }

        /**
            The callback function that runs whenever one of these resources is destroyed using the Burner instance.
            Destroying an Election resource can, potentially, leave a whole slew of Ballots still stored in the resource kinda dangling. They still exist is the blockchain, but it is impossible to access them because the resource housing them was destroyed. To prevent this, this callback goes ahead and destroys any Ballot in storage as well. The number of Ballots destroyed in this process is indicated in the final event emitted
        **/
        access(contract) fun burnCallback(): Void {

            // Start by getting the keys of all the Ballots still in storage
            let submittedBallotsOwners: [Address] = self.submittedBallots.keys

            // Take note of the number of Ballots in storage
            let totalBallotsInStorage: UInt = UInt(self.submittedBallots.length)

            // Use these keys to load and destroy each Ballot
            for submittedBallotOwner in submittedBallotsOwners {
                // Load Ballots one at a time as optional. If they came up as nil, ignore it and move on because there's no need to process these
                let ballotToBurn: @{BallotStandard.Ballot}? <- self.submittedBallots.remove(key: submittedBallotOwner)

                // Use the Burner contract to destroy these Ballots so that the proper events get emitted as well
                Burner.burn(<- ballotToBurn)

                // Decrement both the total number of Ballots minted and submitted, just to keep things consistent
                self.decrementTotalBallotsMinted(ballots: 1)
                self.decrementTotalBallotsSubmitted(ballots: 1)
            }

            // Emit the relevant event
            emit ElectionDestroyed(_electionId: self.electionId, _ballotsSubmitted: totalBallotsInStorage)
        }
    }
}
/*
    I'm killing two birds with one stone with this one. I came to the conclusion that the best approach for this system is not to have one contract per election (which would require deploying a new contract whenever a new election was needed, which would defeat the purpose of this system in the first place) but to have a easy way to create multiple elections with only one contract, like in a function or something of the sort. The obvious solution? To abstract elections as resources! It is surprising to see how useful linear types and resources are, especially in this context. Anyway, need requires a profound modification of the current contract. But since I'm moving in this direction, might as well take the opportunity to do the other thing that I wanted to do, which was to remove the NonFungibleToken standard requirement. No disrespect to Flow (on the contrary actually), but the NFT standard is actually making this worse than it needs to be. I mean, the standard was created to regulate digital collectibles, which is similar to what I want to do, but not quite enough for it to be useful to me. I now know enough of Cadence to make my own standards (which I will at some point...) as well as do this without one. So, lets roll the sleeves and get cracking...
*/
import "Burner"
import "BallotToken"

access(all) contract VoteBooth {
    // STORAGE PATHS
    access(all) let ballotPrinterAdminStoragePath: StoragePath
    access(all) let ballotPrinterAdminPublicPath: PublicPath
    access(all) let ballotBoxStoragePath: StoragePath
    access(all) let ballotBoxPublicPath: PublicPath
    access(all) let voteBoxStoragePath: StoragePath
    access(all) let voteBoxPublicPath: PublicPath
    access(all) let ownerControlStoragePath: StoragePath
    access(all) let ownerControlPublicPath: PublicPath
    access(all) let burnBoxStoragePath: StoragePath
    access(all) let burnBoxPublicPath: PublicPath

    // CUSTOM EVENTS
    access(all) event NonNilTokenReturned(_tokenType: Type)
    // Event for when a new Ballot is created
    access(all) event BallotMinted(_ballotId: UInt64, _electionId: UInt64)

    // Event for when a Ballot is destroyed
    access(all) event BallotBurned(_ballotId: UInt64, _electionId: UInt64)

    // Event for when a Ballot is successfully submitted for tally
    access(all) event BallotSubmitted(_ballotId: UInt64, _electionId: UInt64)

    // Event for when a Ballot is replaced by another Ballot with a different option (or not. It's pointless but is possible for a voter to re-submit a Ballot with the same option as before). The event indicates which Ballot was replaced and which one replaced it.
    access(all) event BallotModified(_oldBallotId: UInt64, _newBallotId: UInt64, _electionId: UInt64)

    // Event for when a Ballot is revoked.
    access(all) event BallotRevoked(_ballotId: UInt64, _electionId: UInt64)

    access(all) event ContractDataInconsistent(_ballotId: UInt64?, _owner: Address?)
    access(all) event VoteBoxCreated(_voterAddress: Address)
    access(all) event VoteBoxDestroyed(_ballotsInBox: Int, _ballotId: UInt64?)
    access(all) event BallotBoxCreated(_accountAddress: Address)
    access(all) event ElectionCreated(_electionId: UInt64)
    access(all) event ElectionDestroyed(_electionId: UInt64)
    access(all) event BallotsWithdrawn(ballots: UInt)
    // This event should emit when a Ballot is deposited in a BurnBox. NOTE: this doesn't mean that the Ballot was burned, it just set into an unrecoverable place where the Ballot is going to be burned at some point
    access(all) event BallotSetToBurn(_ballotId: UInt64, _voterAddress: Address)

    // CUSTOM ENTITLEMENTS
    access(all) entitlement BoothAdmin

    // CUSTOM VARIABLES
    // Election resources are going to be stored in their own dictionary. The key is the electionId, the value is the Election resource itself.
    access(self) var elections: @{UInt64: VoteBooth.Election}

    // I'm setting the default Ballot option as a variable for easier comparison
    access(all) let defaultBallotOption: UInt8?

    // Use this variable set (the contract constructor receives an argument to set it) to enable or disable the printing of logs in this project
    access(all) let printLogs: Bool

    // CUSTOM RESOURCES
// ----------------------------- ELECTION START ----------------------------------------------------
/*
    This resource is going to be used to handle multiple elections, namely, I'm going to create one per election. An election in this context is a question, a policy suggestion, etc. Mainly, it's a question that voters should give their opinion on. Because I want to have people voting for multiple items at one point, I need to change this in such a way that elections should be easy to create, as well as being able to track which voters have submitted votes to a specif election and so on.
*/
access(all) resource Election: Burner.Burnable {
    // The usual parameters that describe the election
    access(self) let electionId: UInt64
    access(all) let _name: String
    access(all) let _ballot: String
    access(all) let _options: [UInt8]

    // I need to keep track of the Ballots minted and submitted per election
    access(self) var totalBallotsMinted: UInt
    access(self) var totalBallotsSubmitted: UInt

    access(all) let _defaultBallotOption: UInt8?

    access(self) var submittedBallots: @{Address: VoteBooth.Ballot}

    // Set of getters for the election parameters
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

    // And now the getters and setters for the totals
    access(all) view fun getTotalBallotsMinted(): UInt {
        return self.totalBallotsMinted
    }

    access(all) view fun getTotalBallotsSubmitted(): UInt {
        return self.totalBallotsSubmitted
    }

    access(account) fun incrementTotalBallotsMinted(ballots: UInt): Void {
        self.totalBallotsMinted = self.totalBallotsMinted + 1
    }

    access(account) fun incrementTotalBallotsSubmitted(ballots: UInt): Void {
        self.totalBallotsSubmitted = self.totalBallotsSubmitted + 1
    }

    access(account) fun decrementTotalBallotsMinted(ballots: UInt): Void {
        // I'm using unsigned integers to represent these totals, which means that any subtraction that bring this value to < 0 throws an underflow error. Nevertheless, I'm doing a check and raising my own error (panic) just to have a more obvious error message than the underflow one.
        if (ballots > self.totalBallotsMinted) {
            panic(
                "Unable to decrease the total Ballots minted! Cannot decrease a total of "
                .concat(self.totalBallotsMinted.toString())
                .concat(" minted Ballots by ")
                .concat(ballots.toString())
                .concat(" without triggering an underflow error!")
            )
        }

        // Proceed with the subtraction if the error above was not triggered
        self.totalBallotsMinted = self.totalBallotsMinted - ballots
    }

    access(account) fun decrementTotalBallotsSubmitted(ballots: UInt): Void {
        if (ballots > self.totalBallotsSubmitted) {
            panic(
                "Unable to decrease the total Ballots submitted! Cannot decrease a total of "
                .concat(self.totalBallotsSubmitted.toString())
                .concat(" submitted Ballots by ")
                .concat(ballots.toString())
                .concat(" without triggering an underflow error!")
            )
        }

        self.totalBallotsSubmitted = self.totalBallotsSubmitted - ballots
    }

    /**
        This function submits a Ballot provided as argument into the internal Election storage. This Ballot, if valid, is anonymized (ballotOwner and voteBoothDeployer parameters set to nil) and stored in a Address -> Ballot dictionary. So, there's a tenuous (but private) link between a submitted Ballot and the user that submitted it, but is not able to be accessed (let alone modified) by an unauthorized party. Why? Because this dictionary is access(self), therefore only the Election resource itself can access this dictionary. Once submitted, a Ballot is either sent to a TallyBox for counting (still in its anonymized version) or can be removed if the original voter submits a revoke Ballot (a Ballot with the defaultBallotOption set). Also, if the user/voter changes his/her mind and wants to change their opinion, they can simply submit another Ballot. Since I'm storing only one Ballot per Address, any Ballots submitted after the first one replaces any older one.

        @param: ballot (@VoteBooth.Ballot) The ballot to be submitted to this Election instance
    **/
    access(all) fun submitBallot(ballot: @VoteBooth.Ballot): Void {
        pre{
            ballot.ballotOwner != nil: "Anonymous Ballot provided! The Ballot submitted is not registered to a valid address!"
            ballot.electionId != self.electionId: "The Ballot provided was registered to Election ".concat(ballot.electionId.toString()).concat(" but this Election has id ".concat(self.electionId.toString()).concat(". Please submit the right Ballot or chose the right Election!"))
        }

        // Grab a reference to the value currently set in the position indicated by the Ballot
        let newBallotId: UInt64 = ballot.ballotId
        let newOwner: Address = ballot.ballotOwner!

        let randomResourceRef: &AnyResource? = &self.submittedBallots[newOwner]

        // Anonymize the Ballot before moving forward
        ballot.anonymizeBallot()

        // Test the reference obtained above and proceed accordingly
        if (randomResourceRef == nil) {
            // This is the initial case for every first submission: there are no Ballots in storage at the ballotOwner spot yet.
            if (ballot.isRevoked()) {
                // If this Ballot is a revoke, there's not a lot to do since there's no other Ballot in storage in that position. As such, burn the Ballot provided
                Burner.burn(<- ballot)

                // Decrement the total number of ballots minted because of the last burn
                self.decrementTotalBallotsMinted(ballots: 1)

                // Emit the BallotRevoked event but with the parameters from the Ballot just burned
                emit BallotRevoked(_ballotId: newBallotId, _electionId: self.electionId)
                //emit BallotToken.BallotRevoked(_ballotId: newBallotId, _electionId: self.electionId)
            }
            else {
                // Otherwise, it's a normal submission. Process with it
                let randomResource: @AnyResource? <- self.submittedBallots[newOwner] <- ballot

                // Cadence is super type specific and super picky when it comes to store resources (and rightfully so!), which requires me to retrieve this randomResource, even though I've "proved" that there's nothing (nil) in that position. The cost of this is minimal, so move on
                destroy randomResource

                // Emit the respective event
                emit VoteBooth.BallotSubmitted(_ballotId: newBallotId, _electionId: self.electionId)

                // Increase the total number of ballots submitted to this Election
                self.incrementTotalBallotsSubmitted(ballots: 1)

            }
        }
        else if (randomResourceRef.getType() == Type<&VoteBooth.Ballot?>()) {
            // In this case, there's an older Ballot in this position. This is either a revoke or a re-submission. Test it and act accordingly
            // Start by removing the old Ballot from storage
            let oldBallot: @VoteBooth.Ballot <- self.submittedBallots.remove(key: newOwner) as! @VoteBooth.Ballot

            let oldBallotId: UInt64 = oldBallot.ballotId

            // The owner of the old Ballot is no longer in the Ballot itself because it gets anonymized before being stored. But the one constant in this function is the owner itself, so I can simply reutilize this parameter and move on.
            let oldOwner: Address = newOwner

            // Destroy the old Ballot and store the new one in its place. Use the Burner for this to run the burnCallback in the Ballot resource
            Burner.burn(<- oldBallot)

            // Anytime a Ballot gets burned, I need to decrement the ballot totals. For now, by burning the old Ballot, all I can guarantee at the moment is that the total minted needs to be decremented by 1
            self.decrementTotalBallotsMinted(ballots: 1)

            // Check if the new Ballot is a revoke one
            if (ballot.isRevoked()) {
                // This means that the storage slot is to remain empty. Therefore proceed with burning the new Ballot as well
                Burner.burn(<- ballot)

                // Emit the BallotRevoked event but with the data from the old Ballot, since it was the one that got revoked after all
                emit VoteBooth.BallotRevoked(_ballotId: oldBallotId, _electionId: self.electionId)

                // Decrement the total Ballots minted due to another Ballot being burned
                self.decrementTotalBallotsMinted(ballots: 1)

                // But also the total submitted because there was no Ballot replacing the old one, which had been counted into the totals submitted before
                self.decrementTotalBallotsSubmitted(ballots: 1)
            }
            else {
                // Otherwise, this is a re-submission. I still needed to destroy the old Ballot (which I already did) but now I need to put the new one in its place
                let nilResource: @AnyResource? <- self.submittedBallots[newOwner] <- ballot

                // This nil resource is nothing but a nil, but it still needs to be destroyed because Cadence is picky as hell in this regard. This is not a complaint. After all, it's all this pickiness that makes this whole thing work in the first place!
                destroy nilResource

                // Emit a BallotModified event with the details of the Ballots, which are still available
                emit VoteBooth.BallotModified(_oldBallotId: oldBallotId, _newBallotId: newBallotId, _electionId: self.electionId)

                // There's no need to adjust any Ballot totals at this point. All totals are consistent at this moment.
            }
        }
        else {
            // There is one last scenario that is highly unlikely, impossible even in this kind of platform, but the good programmer I believe to be is not able to sleep peacefully without taking care of it. There's a very, very small probability of having something else that is not a Ballot, nor a nil in the ballotSubmitted position. Deal with it
            if (ballot.isRevoked()) {
                // Same as before. I need to deal with a revoke in a different fashion than for normal submissions
                let nonNilResource: @AnyResource <- self.submittedBallots.remove(key: newOwner)

                // I have a custom event just for these cases
                emit VoteBooth.NonNilTokenReturned(_tokenType: nonNilResource.getType())

                // But there's not a lot to do after. Destroy the non nil resource
                destroy nonNilResource

                // And burn the revoke Ballot
                Burner.burn(<- ballot)

                // Emit the BallotRevoked event but with the ballotId set to nil because this has not revoked any Ballots
                emit VoteBooth.BallotRevoked(_ballotId: newBallotId, _electionId: self.electionId)

                // Adjust the totals by decrementing the total ballots minted to account for the burned Ballot
                self.decrementTotalBallotsMinted(ballots: 1)
            }
            else {
                // Similar scenario. Emit the NonNilReturned event to start
                let nonNilResource: @AnyResource <- self.submittedBallots[newOwner] <- ballot

                emit VoteBooth.NonNilTokenReturned(_tokenType: nonNilResource.getType())

                // The new Ballot got submitted anyway, so emit the relevant event as well
                emit VoteBooth.BallotSubmitted(_ballotId: newBallotId, _electionId: self.electionId)

                // Increment the total ballots submitted because of the new Ballot just submitted
                self.incrementTotalBallotsSubmitted(ballots: 1)

                // Finish by destroying whatever was in storage before
                destroy nonNilResource
            }
        }
    }

    /**
        This function removes the Ballots in storage in an even more anonymized fashion, thus increasing the level of voter privacy. Right now, the only link between a submitted Ballot and the voter that casted it is the address used as key for the submittedBallots internal dictionary. This function simply returns the values of such dictionary.
        Due to the sensitive nature of this function, it can only be invoked with a TallyAdmin entitlement, which requires a borrow from storage, which implies that only this contract deployer can use it. Gotta love how simple and secure these things have become!

        @return: @[VoteBooth.Ballot] Returns an array with all the Ballots in no specific order, as stipulated in the Cadence documentation. The expectation is that this is going to build upon the voter privacy principles enacted thus far.
    **/
    access(BallotToken.TallyAdmin) fun withdrawBallots(): @[VoteBooth.Ballot] {
        // Because I have a bunch of resources as values in an internal dictionary, Cadence does not allows me to simply do a "return <- self.submittedBallots.values" willy nilly. I need to "manually" extract each Ballot into an array to be able to return them
        var ballotsToTally: @[VoteBooth.Ballot] <- []

        // I need to do this in a loop
        let storageAddresses: [Address] = self.submittedBallots.keys

        for storageAddress in storageAddresses {
            ballotsToTally.append(<- self.submittedBallots.remove(key: storageAddress)!)
        }

        // Emit the event with the total of Ballots to return
        emit VoteBooth.BallotsWithdrawn(ballots: UInt(ballotsToTally.length))

        // And return the array of Ballot references
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
        The callback function that runs whenever one of this resources is destroyed using the Burner instance.
    **/
    access(contract) fun burnCallback(): Void {
        // TODO: Should I panic if someone tries to burn an Election that has Ballots still in it? Consider...
        emit VoteBooth.ElectionDestroyed(_electionId: self.electionId)
    }

    init(name: String, ballot: String, options: [UInt8]) {
        // This one is obtained automatically
        self.electionId = self.uuid
        
        self._name = name
        self._ballot = ballot
        self._options = options

        self.totalBallotsMinted = 0
        self.totalBallotsSubmitted = 0

        // The default ballot option is automatically inherited from the contract itself
        self._defaultBallotOption = VoteBooth.defaultBallotOption

        self.submittedBallots <- {}
    }
}
// ----------------------------- ELECTION END ------------------------------------------------------

// ----------------------------- BALLOT BEGIN ------------------------------------------------------
    /*
        This is the main actor in this process. The Ballot NFT is issued on demand, is editable by the voter, and can be submitted by transferring it to a VoteBooth contract
    */
    access(all) resource Ballot: BallotToken.Ballot {
        /// The main token id, issued by Flow's internal uuid function
        access(all) let ballotId: UInt64

        /// The main option to represent the choice. A nil indicates none selected yet
        access(BallotToken.VoteEnable) var option: UInt8?

        /// The address to the VoteBooth contract deployer. This is useful to be able to retrieve references to deployer bound resources through accessing public capabilities.
        access(all) let voteBoothDeployer: Address

        /// The id of the Election resource that this Ballot is associated with.
        access(all) let electionId: UInt64

        access(all) let defaultBallotOption: UInt8?

        access(all) var ballotOwner: Address?
        
        /**
            Burner callBack function to be automatically called when the Burner.burn function is invoked on a Ballot resource. This call back simply emits the related event.
        **/
        access(contract) fun burnCallback() {
            if (VoteBooth.printLogs) {
                log(
                    "burnCallback called for Ballot with id "
                    .concat(self.ballotId.toString())
                    .concat(self.owner!.address == nil ? " (anonymous)" : " for owner ".concat(self.owner!.address.toString()))
                )
            }
            emit BallotBurned(_ballotId: self.ballotId, _electionId: self.electionId)
        }

        /**
            Function that uses this Ballot's electionId, which points to a valid @VoteBooth.Election resource, to get a reference to the Election resource and then use that resource to retrieve the election name.

            @return: String Returns the name of the election resource associated with this Ballot.
        **/
        access(all) view fun getElectionName(): String {

            let electionRef: &VoteBooth.Election? = VoteBooth.borrowElection(electionId: self.electionId)

            // I don't expect this situation to happen ever, but just in case...
            if (electionRef == nil) {
                panic(
                    "ERROR: Unable to retrieve a valid &VoteBooth.Election for electionId "
                    .concat(self.electionId.toString())
                    .concat(". This should not happen! Ballots cannot be minted outside of a valid @Election!")
                )
            }
            
            // All good. Run the respective function from the reference instead
            return electionRef!.getElectionName()
        }

        /**
            Function that uses this Ballot's electionId, which points to a valid @VoteBooth.Election resource, to get a reference to the Election resource and then use that resource to retrieve the election ballot text. This is the question that is to be answered by the voter.

            @return: String Returns the ballot text for the election resource associated with this Ballot.
        **/
        access(all) view fun getElectionBallot(): String {
            let electionRef: &VoteBooth.Election? = VoteBooth.borrowElection(electionId: self.electionId)

            // Deal with the impossible situation nonetheless
            if (electionRef == nil) {
                panic(
                    "ERROR: Unable to retrieve a valid &VoteBooth.Election for electionId "
                    .concat(self.electionId.toString())
                    .concat(". This should not happen! Ballots cannot be minted outside of a valid @Election!")
                )
            }

            return electionRef!.getElectionBallot()
        }

        /**
            Function that uses this Ballot's electionId, which points to a valid @VoteBooth.Election resource, to get a reference to the Election resource and the use that resource to retrieve the available options for the current ballot.

            @return: [UInt8] The array of numerical options where the Ballot can be casted into.
        **/
        access(all) view fun getElectionOptions(): [UInt8] {
            let electionRef: &VoteBooth.Election? = VoteBooth.borrowElection(electionId: self.electionId)

            if (electionRef == nil) {
                panic(
                    "ERROR: Unable to retrieve a valid &VoteBooth.Election for electionId "
                    .concat(self.electionId.toString())
                    .concat(". This should not happen! Ballots cannot be minted outside of a valid @Election!")
                )
            }

            return electionRef!.getElectionOptions()
        }

        // The Ballot resource constructor
        init(_ballotOwner: Address, _voteBoothDeployer: Address, _electionId: UInt64) {
            // The Ballot id is obtained automatically
            self.ballotId = self.uuid
            self.option = VoteBooth.defaultBallotOption
            self.ballotOwner = _ballotOwner
            self.voteBoothDeployer = _voteBoothDeployer
            self.electionId = _electionId
            self.defaultBallotOption = VoteBooth.defaultBallotOption

        }
    }
// ----------------------------- BALLOT END --------------------------------------------------------

// ----------------------------- VOTE BOX BEGIN ----------------------------------------------------
// TODO: Review this one under the new multiple Election paradigm
    access(all) resource VoteBox: Burner.Burnable {
        /*
            I'm only allowing one Ballot at a time in this VoteBox resource. The easier way is to define it as a single variable, with access(self) for maximum protection. But unfortunately, Flow/Cadence does like at all to mess around with nested resources unless they are set in some sort of storing structure. I can do this with an array, but a dictionary is better because it has a bunch of really useful base function
        */
        access(self) var storedBallot: @{UInt64: VoteBooth.Ballot}
        
        // I'm going to use these variables to ease the access to the stored Ballot without having to load it or get a reference to it all the time. Since I'm only going to have one at a time, this works
        access(self) var storedBallotOwner: Address?
        access(self) var storedBallotId: UInt64?

        // Set the owner of this VoteBox at the constructor level to ensure that only this address can withdraw Ballots from it
        access(self) let voteBoxOwner: Address
        
        // Simple function to determine if this VoteBox already has a Ballot in it or not
        access(all) view fun hasBallot(): Bool {
            if (self.storedBallot.length == 0) {
                return false
            }

            return true
        }

        // This function return the voteBoothDeployer address but does so by getting it from the Ballot, if any is stored. If not, a nil is returned
        access(all) view fun getVoteBoothDeployer(): Address? {
            if (self.storedBallot.length == 0) {
                // No Ballots in storage yet. Return nil
                return nil
            }
            else {
                // Grab a reference for the Ballot in storage
                let storedBallotRef: &VoteBooth.Ballot? = &self.storedBallot[self.storedBallotId!]

                return storedBallotRef!.voteBoothDeployer
            }
        }

        // Function to deposit a Ballot into this VoteBox. Though this Collection (of sorts. Its not a standard one) can theoretically receive multiple Ballots, I'm sticking it to a single Ballot at all times through a clever use of pre and post conditions, as well as with an exhaustive (perhaps too much even) set of internal validations, both in this function and others related.
        access(all) fun depositBallot(ballot: @VoteBooth.Ballot) {
            // Each one of these boxes can only hold one vote of one type at a time. Validate this
            pre {
                // This pre-condition is everything really. It only allows the deposit of a Ballot if there are none stored yet. After storing one Ballot, it is impossible to deposit another one: this pre-condition stop this function for every self.storedBallots >= 1
                self.owner != nil: "Deposit is only allowed through a reference."
                self.storedBallot.length == 0: "Account ".concat(self.owner!.address.toString()).concat(" already has a Ballot in storage. Submit it or burn it to continue.")
                // Ensure also that a Ballot with a different owner does not gets deposited. It should be impossible, given all the validations up to this point, but just in case
                self.owner!.address == ballot.ballotOwner: "Unable to deposit a Ballot with a different owner than the one in this VoteBox (".concat(self.owner!.address.toString()).concat(")")
            }

            post {
                // Nevertheless, I'm going to be extremely paranoid with this one, therefore I'm also setting a post condition to guarantee that this whole thing blows up if, at any point, this VoteBox has more than one Ballot in storage
                self.storedBallot.length <= 1: "Account ".concat(self.owner!.address.toString()).concat(" contains multiple Ballots (> 1) in storage! VoteBoxes are limited to 1, maximum!")
            }

            // Set the other internal properties first before losing access to the Ballot resource
            self.storedBallotOwner = ballot.ballotOwner
            self.storedBallotId = ballot.ballotId

            // Deposit the Ballot
            let randomResource: @AnyResource? <- self.storedBallot[ballot.ballotId] <- ballot

            // This is a theoretically impossible scenario, but deal with it just in case.
            if (randomResource.getType() == Type<@VoteBooth.Ballot>()) {
                panic(
                    "ERROR: There was a @VoteBooth.Ballot already stored in a VoteBox for address "
                    .concat(self.owner!.address.toString())
                    .concat(". This cannot happen!")
                )
            }
            // The expectation is that, at all times, a type Never? is returned if the internal dictionary is empty. If that is not the case, emit the NonNilTokenReturned event, but proceed with the destruction of the randomResource
            else if (randomResource.getType() != Type<Never?>()) {
                emit VoteBooth.NonNilTokenReturned(_tokenType: randomResource.getType())
            }

            // Done with all of that. Destroy the random resource
            destroy randomResource
        }

        /*        
            If the VoteBox has a Ballot, it returns its owner. If not, returns a nil instead, as usual. Getting the Ballot owner is pretty innocuous, but I'm protecting it with access(account) so that only the owner of the account can access it. This restricts this to transactions, which is OK. I don't want this kind of information out there to protect the voter privacy for as much as I can.
            TODO: Delete/Protect this functions before moving to PROD. It's not a big deal, but it does sacrifices a tiny bit of voter privacy. Or maybe encrypt this in the future?
        */
        access(all) fun getBallotOwner(): Address? {
            // This one becomes super easy with the structure I'm using
            return self.storedBallotOwner
        }

        // TODO: This one needs to be deleted or protected before moving to PROD.
        access(all) view fun getBallotId(): UInt64? {
            // And this one too
            return self.storedBallotId
        }

        // Set this function to be called whenever I destroy one of these VoteBoxes. IMPORTANT: For this to work, I need to use the Burner contract to destroy any VoteBoxes. If I simply use the 'destroy' function, this function is not called!
        access(contract) fun burnCallback() {
            // Prepare this to emit the VoteBoxDestroyed event, namely, check if there's any Ballot stored, and if it is, grab its Id first
            let ballotId: UInt64? = self.storedBallotId

            // If the ballotId is not nil, do this properly and burn the Ballot before finishing
            if (ballotId != nil) {
                let ballotToBurn: @VoteBooth.Ballot <- self.storedBallot.remove(key: ballotId!)!

                // Even though this resource is about to be destroyed, I'm super prickly with everything. Just to be consistent with the awesome programmer that I am, set the internal storedBallotOwner and storedBallotId to nil. It's pointless, but that how I roll
                self.storedBallotId = nil
                self.storedBallotOwner = nil

                /*
                    In order to properly destroy (burn) any Ballot still in storage, send it to the VoteBooth deployer's BurnBox instead. At this level, this resource is unable to access the OwnerControl resource (only this deployer can do that) to maintain contract data consistency, i.e., to remove the respective entries from the internal dictionaries and such. Sending this Ballot to the BurnBox, which I can get from this resource because the reference to it is publicly accessible, solves all these problems. As such, I've set the contract deployer address, as in the address associated with the ballotPrinterAdmin resource required to mint the Ballot in the first place, as a access(all) parameter in the Ballot resource. Do it
                */
                let burnBoxRef: &VoteBooth.BurnBox = getAccount(ballotToBurn.voteBoothDeployer).capabilities.borrow<&VoteBooth.BurnBox>(VoteBooth.burnBoxPublicPath) ??
                panic(
                    "Unable to retrieve a valid &VoteBooth.BurnBox at "
                    .concat(VoteBooth.burnBoxPublicPath.toString())
                    .concat(" from account ")
                    .concat(ballotToBurn.voteBoothDeployer.toString())
                )

                // Send the Ballot to the BurnBox
                burnBoxRef.depositBallotToBurn(ballotToBurn: <- ballotToBurn)
            }

            // Emit the respective event. NOTE: any ballotId emitted with this event refers to a Ballot set to burn in a BurnBox and not a Ballot that was destroyed
            // Just a reminder: I'm using a ternary operator to define the number of Ballots in the box that was destroyed. It reads as: is ballotId a nil ? if true, no Ballots in storage, thus set a 0. If not, there was one Ballot in storage, thus set a 1 instead.
            emit VoteBooth.VoteBoxDestroyed(_ballotsInBox: ballotId == nil ? 0 : 1, _ballotId: ballotId)
        }

        /*
            NOTE: This function is for TEST and DEBUG purposes only.
            This function returns the current option in a Ballot stored internally, or nil if there are none.
            I've set the protections to prevent people other than the owner in the Ballot resource itself. If someone else tries to fetch the current vote other than the Ballot owner (which is also the VoteBox owner by obvious reasons), it fails a pre condition and panics. If there are no Ballots yet in the VoteBox, a nil is returned instead.
            TODO: Delete or protect this function with a proper entitlement before moving this to PROD
        */
        access(BallotToken.TallyAdmin) fun getCurrentVote(): UInt8? {
            // Grab the id for the Ballot in storage, if any
            if (self.storedBallot.length == 0) {
                // If there are no Ballots stored yet, return a nil
                return nil
            }
            else if (self.storedBallot.length > 1) {
                // If by some reason there are more than 1 Ballot stored, panic. I've made all sort of checks up to this point in this sense, but one more doesn't hurt. The contract is gigantic, but its worth it
                panic(
                    "ERROR: VoteBox for account "
                    .concat(self.owner!.address.toString())
                    .concat(" has ")
                    .concat(self.storedBallot.length.toString())
                    .concat(" Ballots in it. Only one is allowed, max!")
                )
            }
            
            // Grab a reference to the ballot stored
            let storedBallotRef: auth(BallotToken.TallyAdmin) &VoteBooth.Ballot? = &self.storedBallot[self.storedBallotId!]

            // Just to be sure, check if the reference obtained is not nil. Panic if, by some reason, it is
            if (storedBallotRef == nil) {
                panic(
                    "Unable to get a valid &{NonFungibleToken.NFT} for ballotId "
                    .concat(self.storedBallotId!.toString())
                )
            }

            // Check also that the VoteBox owner and the Ballot owner match. I mean, it is impossible for a VoteBox to store a Ballot from a different owner, given all the checks and balances that I've placed so far, but check it just in case
            if(self.voteBoxOwner != storedBallotRef!.ballotOwner) {
                panic(
                    "ERROR: Somehow the Ballot stored has owner "
                    .concat(storedBallotRef!.ballotOwner!.toString())
                    .concat(" while this VoteBox has owner ")
                    .concat(self.voteBoxOwner.toString())
                    .concat(". These two need to match!")
                )
            }

            // Invoke the function from the ballot reference itself.
            return storedBallotRef!.getVote()
        }

        /*
            This is the function used to cast a Vote. It verifies an insane number of pre and post conditions, but if successful, it changes the option field in a stored Ballot, which equates to a valid vote
        */
        access(BallotToken.VoteEnable) fun castVote(option: UInt8?) {
            pre {
                self.owner != nil: "Voting is only allowed through an authorized reference!"
                self.storedBallot.length > 0: "Account ".concat(self.owner!.address.toString()).concat(" does not have a Ballot in storage to vote!")
                self.storedBallot.length <= 1: "Account ".concat(self.owner!.address.toString()).concat(" has multiple Ballots in storage! This cannot happen!")
                self.storedBallotOwner != nil: "VoteBox for account ".concat(self.owner!.address.toString()).concat(" has a Ballot in storage but the internal owner is not set. Unable to continue.")
                self.storedBallotId != nil: "VoteBox for account ".concat(self.owner!.address.toString()).concat(" has a Ballot in storage but the internal id is not set. Unable to continue.")
                self.storedBallotOwner! == self.owner!.address: "The VoteBox owner(".concat(self.owner!.address.toString()).concat(") is different from the Ballot owner(").concat(self.storedBallotOwner!.toString()).concat("). Cannot continue!")
            }

            post {
                before(self.storedBallot.length) == self.storedBallot.length: "This function should not change the number of Ballots in storage!"
            }

            // Get a reference to the stored Ballot
            let storedBallotRef: auth(BallotToken.VoteEnable) &VoteBooth.Ballot? = &self.storedBallot[self.storedBallotId!]

            if (storedBallotRef == nil) {
                panic(
                    "ERROR: Unable to get a valid &VoteBooth.Ballot with stored id "
                    .concat(self.storedBallotId!.toString())
                    .concat(" for VoteBox in account ")
                    .concat(self.owner!.address.toString())
                )
            }

            // All is OK so far. Do it.
            storedBallotRef!.vote(newOption: option)            
        }

        /*
            I'm going to split the casting of a vote and the submission of said vote in different function. Maybe I'll regret this in the future, but for now it seems the best approach. The cast vote above changes the vote in a stored Ballot. The following submit vote sends it to the VotingBooth's contract BallotBox to be tallied at a future point.
        */
        access(VoteEnable) fun submitBallot() {
            // Make sure that everything is correct for submit the Ballot
            pre {
                self.owner != nil: "Ballots can only be submitted from an authorized reference!"
                self.storedBallot.length > 0: "No Ballots stored in the VoteBox for account ".concat(self.owner!.address.toString())
                self.storedBallot.length <= 1: "Multiple Ballots detected for the VoteBox for account ".concat(self.owner!.address.toString())
                self.storedBallotOwner != nil: "The VoteBox for account ".concat(self.owner!.address.toString()).concat(" doesn't have a valid owner set for the Ballot in storage. Cannot continue!")
                self.storedBallotId != nil: "The VoteBox for account ".concat(self.owner!.address.toString()).concat(" doesn't have a valid id set for the Ballot in storage. Cannot continue!")
                self.storedBallotOwner! == self.owner!.address: "Only the owner can submit a Ballot."
            }

            post {
                // Check that the VoteBox was reset after submission
                self.storedBallot.length == 0: "The Ballot was not properly submitted!"
                self.storedBallotId == nil: "The stored Ballot id was not reset!"
                self.storedBallotOwner == nil: "The stored Ballot owner was not reset!"
            }
        
            // All good. Grab the Ballot in storage
            let ballotToSubmit: @VoteBooth.Ballot <- self.storedBallot.remove(key: self.storedBallotId!) ??
            panic(
                "Unable to load a @VoteBooth.Ballot for a VoteBox in account "
                .concat(self.owner!.address.toString())
            )

            // Use the voteBoothDeployer address to retrieve a reference to the BallotBox to where the Ballot is to be submitted
            let voteBoothDeployerAccount: Address = ballotToSubmit.voteBoothDeployer!
            let ballotBoxRef: &VoteBooth.BallotBox = getAccount(voteBoothDeployerAccount).capabilities.borrow<&VoteBooth.BallotBox>(VoteBooth.ballotBoxPublicPath) ??
            panic(
                "Unable to get a valid &VoteBooth.BallotBox in "
                .concat(VoteBooth.ballotBoxPublicPath.toString())
                .concat(" for account ")
                .concat(voteBoothDeployerAccount.toString())
            )

            // Submit the ballot to the BallotBox
            ballotBoxRef.submitBallot(ballot: <- ballotToSubmit)

            // Reset the internal ballotId and owner. NOTE: No need to emit any events. The BallotBox resource is the one that does that
            self.storedBallotId = nil
            self.storedBallotOwner = nil
        }

        init(ownerAddress: Address) {
            self.storedBallot <- {}
            self.storedBallotOwner = nil
            self.storedBallotId = nil
            self.voteBoxOwner = ownerAddress
        }
    }
// ----------------------------- VOTE BOX END ------------------------------------------------------

// ----------------------------- BALLOT BOX BEGIN --------------------------------------------------
/*
    The BallotBox resource is going to be similar to a collection but not quite. I need it to store the ballots under an address key rather than an UInt64 key to keep one and only one Ballot submitted per voter, i.e., per address. Also, this allows me to properly implement the multiple vote casting feature in a more easy @and flexible manner
*/
access(all) resource BallotBox {
    

    

    // Simple function just to check how many Ballots were submitted thus far
    access(all) view fun getSubmittedBallotCount(): Int {
        return self.submittedBallots.length
    }

    // Another simple function that simply returns if a Ballot for a given address is already in storage (was submitted) or not. This function is BoothAdmin protected to preserve voter privacy as much as possible. I don't anyone other than the contract deployer to be able to determine if a given voter has vote already or not.
    access(BoothAdmin) view fun getIfOwnerVoted(ballotOwner: Address): Bool {
        // Grab a reference to a potential Ballot in the position 'ballotOwner' and test if it is a nil or not. Return false or true accordingly
        let resourceRef: &AnyResource? = &self.submittedBallots[ballotOwner]

        if (resourceRef.getType() == Type<Never?>() || resourceRef.getType() != Type<&VoteBooth.Ballot?>()) {
            // If the resource is a nil (which corresponds to type Never?) or some other type than the VoteBooth.Ballot, return a false. There's no valid Ballot submitted under this address
            return false
        }

        // If the above condition is not triggered, the resource is of the correct type, so return a true instead
        return true
    }

    // The idea with protecting the constructor with an entitlement is to prevent users other than the deployer to create these resources
    access(BoothAdmin) init() {
        self.submittedBallots <- {}
    }
}

// ----------------------------- BALLOT BOX END ----------------------------------------------------

// ----------------------------- BURN BOX BEGIN ----------------------------------------------------
/*
    Okey, since I added a whole security layer around the minting and burning of Ballots (through the OwnerControl), I now have a problem: how can voter burn a Ballot in his/her VoteBox, without BoothAdmin access to a BallotPrinterAdmin, and while maintaining data consistency in the OwnerControl resource, given that, obviously, they don't have access to this resource?
    The solution is to create a (sort of) another Collection, but one without a withdraw function. This collection, which I'm calling BurnBox, to keep things consistent, can be used by any voter that wishes to burn their Ballot. Ballots deposited in this box have no other "exit" other than getting burned because... I'm writing it as so! Man, you gotta love blockchain and smart contracts. No other technology allows me this kind of control! Even if the deployer "forgets" to burn the Ballots in this box (unless I can came up with some sort of periodic burn function of sorts), there's no way to retrieve a Ballot that went into this box. Either they get burned or they stay in there forever.
*/
access(all) resource BurnBox{
    // I'm saving the ballots to be burned in this dictionary. For now, let's keep this one with self access... Maybe it's unnecessary but it doesn't hurt
    access(self) var ballotsToBurn: @{UInt64: VoteBooth.Ballot}

    // This function receives a ballotId as argument, checks if there's a valid entry in the ballotsToBurn dictionary. If so, returns true because the ballot in question is mark for burn. If not, returns a false. This may mean that either no Ballot with that id was received, or the Ballot was burn already
    access(all) fun isBallotToBeBurned(ballotId: UInt64): Bool {
        if (self.ballotsToBurn[ballotId] == nil) {
            return false
        }

        return true
    }

    access(all) fun depositBallotToBurn(ballotToBurn: @VoteBooth.Ballot) {
        // As usual, "clean up" the dictionary entry, while checking if whatever was in the dictionary position IS NOT a valid @VoteBooth.Ballot
        let ballotToBurnId: UInt64 = ballotToBurn.id
        let ballotToBurnOwner: Address = ballotToBurn.ballotOwner!

        // Set the ballot in the dictionary
        let randomResource: @AnyResource? <- self.ballotsToBurn[ballotToBurn.id] <- ballotToBurn

        let randomResourceType: Type = randomResource.getType()

        // This is the worst case: I'm trying to replace an already existing Ballot in this dictionary. Panic in this case to prevent unwanted burns
        if (randomResource != nil && randomResourceType == Type<@VoteBooth.Ballot>()) {
            panic(
                "ERROR: Found a valid @VoteBooth.Ballot already stored with key "
                .concat(ballotToBurnId.toString())
                .concat(". Cannot continue!")
            )
        }
        // The randomResource can be not nil but also not a Ballot. In this case, I need to panic as well. I need to be 100% sure that these things work consistently. 0 room for error in this contract!
        else if (randomResource != nil) {
            panic(
                "ERROR: The BurnBox.ballotsToBurn has a non-nil entry for id "
                .concat(ballotToBurnId.toString())
                .concat(". Found a '")
                .concat(randomResource.getType().identifier)
                .concat("' resource in this slot! Cannot continue")
            )
        }

        // If I got here, all went OK: The randomResource is nil and the ballot to burn is safely stored in the internal dictionary. All there's left to do is to destroy the (nil) randomResource and emit the respective event.
        destroy randomResource

        emit VoteBooth.BallotSetToBurn(_ballotId: ballotToBurnId, _voterAddress: ballotToBurnOwner)
    }
    
    // Get a list of Ids of the Ballots set to burn
    access(BoothAdmin) fun getBallotsToBurn(): [UInt64] {
        return self.ballotsToBurn.keys
    }

    // Simple function to determine how many ballots are set to be burn
    access(all) fun howManyBallotsToBurn(): Int {
        return self.ballotsToBurn.length
    }

    // This is the other important function in this resource. Think of this as the "empty garbage" button. It turns the incinerator on and burns all ballots stored in the internal dictionary. Because of access issues, I kinda need to replicate the burn function from the ballotPrinterAdmin resource
    access(BoothAdmin) fun burnAllBallots(): Void {
        // Get all the dictionary keys in a nice UInt64 list for iteration purposes
        let ballotIdsToBurn: [UInt64] = self.ballotsToBurn.keys

        // I also need a reference for the OwnerControl resource that it is stored in this same account storage
        let ownerControlRef: &VoteBooth.OwnerControl = self.owner!.capabilities.borrow<&VoteBooth.OwnerControl>(VoteBooth.ownerControlPublicPath) ??
        panic(
            "Unable to get a valid &VoteBooth.OwnerControl at "
            .concat(VoteBooth.ownerControlPublicPath.toString())
            .concat(" for account ")
            .concat(self.owner!.address.toString())
        )

        for ballotId in ballotIdsToBurn {
            // Grab a Ballot to process
            let ballotToBurn: @VoteBooth.Ballot <- self.ballotsToBurn.remove(key: ballotId) ??
            panic(
                "Unable to recover a @VoteBooth.Ballot from BurnBox.ballotsToBurn for id "
                .concat(ballotId.toString())
                .concat(". The dictionary returned a nil!")
            )

            // The Ballot set to burn should have valid entries in the OwnerControl resource. Check it
            let storedBallotId: UInt64? = ownerControlRef.getBallotId(owner: ballotToBurn.ballotOwner!)

            if (storedBallotId == nil) {
                // Data inconsistency detected! There is no ballotId associated to the owner in the ballot to burn in the OwnerControl.owners dictionary. Emit the ContractDataInconsistent but don't panic yet. This is recoverable. Ensure the other dictionary is consistent, burn the Ballot and move on
                emit VoteBooth.ContractDataInconsistent(_ballotId: storedBallotId, _owner: ballotToBurn.ballotOwner)

                // This Ballot should not exist. In this case, check the ballotIds dictionary and correct it before burning the Ballot
                let storedBallotOwner: Address? = ownerControlRef.getOwner(ballotId: ballotToBurn.id)

                if (storedBallotOwner != nil) {
                    // Looks like there's an entry in ballotIds dictionary for this ballot. Solve the inconsistency and move on
                    ownerControlRef.removeBallotId(ballotId: ballotToBurn.id, owner: storedBallotOwner!)
                }
            }
            else if (storedBallotId! != ballotToBurn.id) {
                // In this case, the owner of the ballot to burn has a different ballotId associated to it, which means that, theoretically, the owner has two ballots... somehow. In this case, emit two events with the two ballotIds and the same address and then panic... This situation is critical and needs to be taken care before moving on. Ideally this branch should nevern be called
                emit VoteBooth.ContractDataInconsistent(_ballotId: storedBallotId!, _owner: ballotToBurn.ballotOwner)

                emit VoteBooth.ContractDataInconsistent(_ballotId: ballotToBurn.id, _owner: ballotToBurn.ballotOwner)

                panic(
                    "ERROR: Major data inconsistency found: Address "
                    .concat(ballotToBurn.ballotOwner!.toString())
                    .concat(" has two Ballots associated to it: the ballot to burn has id ")
                    .concat(ballotToBurn.id.toString())
                    .concat(" but the OwnerControl.owners has this address associated to ballotId ")
                    .concat(storedBallotId!.toString())
                    .concat(". Cannot continue until this inconsistency is solved!")
                )
            }

            // All data is still consistent. Remove the related entries from both ballotIds and owners dictionaries from the OwnerControl resource and finally burn the damn Ballot. Ish...
            ownerControlRef.removeBallotId(ballotId: ballotToBurn.id, owner: ballotToBurn.ballotOwner!)

            ownerControlRef.removeOwner(owner: ballotToBurn.ballotOwner!, ballotId: ballotToBurn.id)

            // Destroy (burn) the Ballot. This should emit a BallotBurned event
            Burner.burn(<- ballotToBurn)

            // Once a Ballot is destroyed, I also need to decrease the totalBallotsMinted by 1
            VoteBooth.decrementTotalBallotsMinted(ballots: 1)

            // Done. This is the end of the for loop cycle. This should repeat for all ballots set in storage to be burned.
        }
    }

    init() {
        self.ballotsToBurn <- {}
    }

}
// ----------------------------- BURN BOX END ------------------------------------------------------

// ----------------------------- BALLOT PRINTER BEGIN ----------------------------------------------
/*
    To protect the most sensible functions of the BallotPrinterAdmin resource, namely the printBallot function, I'm protecting it with a custom 'BoothAdmin' entitlement defined at the contract level.
    This means that, in order to have the 'printBallot' and 'sot' available in a &BallotPrinterAdmin, I need an authorized reference instead of a normal one.
    Authorized references are indicated with a 'auth(VoteBooth.BoothAdmin) &VoteBooth.BallotPrinterAdmin' and these can only be successfully obtained from the
    'account.storage.borrow<auth(VoteBooth.BoothAdmin) &VoteBooth.BallotPrinterAdmin>(PATH)', instead of the usual 'account.capabilities.borrow...'
    Because I now need to access the 'storage' subset of the Flow API, I necessarily need to obtain this reference from the transaction signer and no one else! The transaction need to be signed by the deployed to work! Cool, that's exactly what I want!
    It is now impossible to call the 'printBallot' function from a reference obtained by the usual, capability-based reference retrievable by a simple account reference, namely, from 'let account: &Account = getAccount(accountAddress)'

    NOTE: VERY IMPORTANT
    This resource can only be used as a reference, never directly as a resource!!
    In other words, never load this, use it, and then put it back into storage. Because, not only it is extremely inefficient from the blockchain point of view, but most importantly, the resource is dangling and, as such, the self.owner!.address is going to break this due to the fact that self.owner == nil! This resource relies A LOT in knowing who the owner of the resource is (mostly because of the OwnerControl resource), so one more reason to avoid this.
*/
    access(all) resource BallotPrinterAdmin {
        // Use this parameter to store the contract owner, given that this resource is only (can only) be created in the contract constructor, and use it to prevent the contract owner from voting. It's a simple but probably necessary precaution.

        access(BoothAdmin) fun printBallot(voterAddress: Address): @VoteBooth.Ballot {
            pre {
                // First, ensure that the contract owner (obtainable via self.owner!.address) does not match the address provided.
                self.owner!.address != voterAddress: "The contract owner is not allowed to vote!"
            }

            let newBallot: @Ballot <- create Ballot(_ballotOwner: voterAddress, _voteBoothDeployer: self.owner!.address)

            // Load a reference to the ownerControl resource from public storage
            let ownerControlRef: &VoteBooth.OwnerControl = self.owner!.capabilities.borrow<&VoteBooth.OwnerControl>(VoteBooth.ownerControlPublicPath) ??
            panic(
                "Unable to get a valid &VoteBooth.OwnerControl at "
                .concat(VoteBooth.ownerControlPublicPath.toString())
                .concat(" for account ")
                .concat(self.owner!.address.toString())
            )

            // Validate that the current owner does not has a Ballot already, i.e., if the resource internal dictionaries are consistent
            // First, check if the address provided has no Ballot associated to it
            let ballotId: UInt64? = ownerControlRef.getBallotId(owner: voterAddress)

            if (ballotId != nil) {
                // Data inconsistency detected. Emit the respective event and panic
                emit VoteBooth.ContractDataInconsistent(_ballotId: ballotId, _owner: voterAddress)

                panic(
                    "ERROR: The address provided ("
                    .concat(voterAddress.toString())
                    .concat(") already has a ballot with id ")
                    .concat(ballotId!.toString())
                    .concat(" issued to it!")
                )
            }

            // This one is a bit "rare", but there's a small possibility of a Ballot with the current Id was already issued, i.e., there's an address already associated to it
            let ballotOwner: Address? = ownerControlRef.getOwner(ballotId: newBallot.id)

            if (ballotOwner != nil) {
                // Same as before: emit the event and panic
                emit VoteBooth.ContractDataInconsistent(_ballotId: ballotId!, _owner: voterAddress)
                
                panic(
                    "ERROR: The Ballot Id generated ("
                    .concat(newBallot.id.toString())
                    .concat(") was already issued to address ")
                    .concat(ballotOwner!.toString())
                    .concat("!")
                )
            }

            // Seems that all went OK so far. Add the required elements to the ownerControl resource
            ownerControlRef.setBallotId(ballotId: newBallot.id, owner: voterAddress)
            ownerControlRef.setOwner(owner: voterAddress, ballotId: newBallot.id)

            emit BallotMinted(_ballotId: newBallot.id, _voterAddress: voterAddress)

            // Increment the number of total Ballots minted by 1 before returning the Ballot
            VoteBooth.incrementTotalBallotsMinted(ballots: 1)

            return <- newBallot
        }

        /*
            This function receives the identification number of a token that was minted by the BoothAdmin Ballot printer and removes all entries from the internal dictionaries. This is useful for when a token is burned, so that the internal contract data structure maintains its consistency.
            For obvious reasons, this function is also BoothAdmin entitlement protected. Also, I've decided to mix the burnBallot function with this one to minimize the probability of creating inconsistencies in these structures
        */
        access(BoothAdmin) fun burnBallot(ballotToBurn: @VoteBooth.Ballot): Void {
            // Get an authorized reference to the OwnerControl resource with a Remove modifier
            let ownerAccount: &Account = getAccount(self.owner!.address)

            let ownerControlRef: &VoteBooth.OwnerControl = ownerAccount.capabilities.borrow<&VoteBooth.OwnerControl>(VoteBooth.ownerControlPublicPath) ??
            panic(
                "Unable to get a valid &VoteBooth.OwnerControl at "
                .concat(VoteBooth.ownerControlPublicPath.toString())
                .concat(" for account ")
                .concat(self.owner!.address.toString())
            )

            // Validate that the Ballot provided is correctly inserted into the OwnerControl structures. Panic if any inconsistencies are detected
            let storedBallotId: UInt64? = ownerControlRef.getBallotId(owner: ballotToBurn.ballotOwner!)

            if (storedBallotId == nil) {
                // Data inconsistency detected! There is no ballotId associated to the owner in the ballot to burn in the 'owners' dictionary. Emit the event but don't panic: make sure both dictionaries are consistent, burn the token and get out
                emit VoteBooth.ContractDataInconsistent(_ballotId: storedBallotId, _owner: ballotToBurn.ballotOwner)

                // This ballot should not exist. In this case, check the other internal dictionary and correct it and burn the ballot before panicking
                let storedBallotOwner: Address? = ownerControlRef.getOwner(ballotId: ballotToBurn.id)

                if (storedBallotOwner != nil) {
                    // It appears that there's a record for this ballot in the owners dictionary. Clean it to keep data consistency
                    ownerControlRef.removeBallotId(ballotId: ballotToBurn.id, owner: storedBallotOwner!)
                }
            }
            else if (storedBallotId! != ballotToBurn.id) {
                // The owner of the ballot to burn has a different ballotId associated to it, which means that, theoretically, the owner has two ballots... somehow. In this case, emit two events with the two ballotIds and the same address and then panic... This situation is critical and needs to be taken care before moving on. Ideally this branch should never be called
                emit VoteBooth.ContractDataInconsistent(_ballotId: storedBallotId!, _owner: ballotToBurn.ballotOwner)

                emit VoteBooth.ContractDataInconsistent(_ballotId: ballotToBurn.id, _owner: ballotToBurn.ballotOwner)

                panic(
                    "ERROR: Major data inconsistency found: Address "
                    .concat(ballotToBurn.ballotOwner!.toString())
                    .concat(" has two Ballots associated to it: the ballot to burn has id ")
                    .concat(ballotToBurn.id.toString())
                    .concat(" but the OwnerControl.owners has this address associated to ballotId ")
                    .concat(storedBallotId!.toString())
                    .concat(". Cannot continue until this inconsistency is solved!")
                )

            }
            else {
                // All is consistent, it seems. Remove related entries from both OwnerControl internal dictionaries. The last step of this function is to burn the ballot provided
                ownerControlRef.removeBallotId(ballotId: ballotToBurn.id, owner: ballotToBurn.ballotOwner!)

                ownerControlRef.removeOwner(owner: ballotToBurn.ballotOwner!, ballotId: ballotToBurn.id)

            }

            // Destroy (burn) the Ballot finally
            Burner.burn(<- ballotToBurn)

            // Decrease the totalBallotsMinted by 1 to account for this burned Ballots
            VoteBooth.decrementTotalBallotsMinted(ballots: 1)
        }

        init() {
        }
    }
// ----------------------------- BALLOT PRINTER END ------------------------------------------------


// ----------------------------- CONTRACT LOGIC BEGIN ----------------------------------------------
    /** 
        Simple burner function to destroy a VoteBox, if needed. This function uses the Burner standard, which allows me to define a burnCallback function in the VoteBox resource to be executed when the destruction of the resource happens through the Burner resource

        @param: voteBoxToBurn (@VoteBooth.VoteBox) The VoteBox resource to burn. 
    **/
    access(account) fun burnVoteBox(voteBoxToBurn: @VoteBooth.VoteBox): Void {
        Burner.burn(<- voteBoxToBurn)
    }
    
    /** 
        Function to create an empty @VoteBooth.VoteBox resource. This function should be invoked via a signed transaction, since this resource is suppose to "live" in the voter's accounts.
        
        @param: owner (Address) VoteBoxes are bound to a single address. I've written these so that they cannot be transferred around, but just in case there's something I'm not foreseeing, I'm creating this extra anchor to guarantee that VoteBoxes are only usable by one and only one user at a time.

        @return: @VoteBooth.VoteBox If successful, a valid @VoteBooth.VoteBox resource is returned.
    **/
    access(all) fun createEmptyVoteBox(owner: Address): @VoteBooth.VoteBox {
        // Create the resource first of all
        let newVoteBox: @VoteBooth.VoteBox <- create VoteBooth.VoteBox(ownerAddress: owner)

        // Emit the respective event before returning the resource
        emit VoteBooth.VoteBoxCreated(_voterAddress: owner)

        // Return the resource to finish this process
        return <- newVoteBox
    }

    /**
        Retrieves a reference to a @VoteBooth.Election resource, is one with the provided electionId exists. This function has an 'access(all)' permission, which means anyone can invoke this. But this is not dangerous because the critical elements of this resource are protected with more restrictive access control.

        @param: electionId (UInt64) The unique identifier for the @VoteBooth.Election resource to retrieve.
        
        @return: &VoteBooth.Election? If a @VoteBooth.Election exists for the electionId provided, this function returns a reference to it. Otherwise a nil is returned instead.
    **/
    access(all) view fun borrowElection(electionId: UInt64): &VoteBooth.Election? {
        return &self.elections[electionId]
    }

// ----------------------------- CONTRACT LOGIC END ------------------------------------------------

// ----------------------------- CONSTRUCTOR BEGIN -------------------------------------------------
/*
    SUPER IMPORTANT NOTE: I want to define this contract to accept a [UInt64] as a election_options argument (which is used to directly set the self._options parameter) but stupid flow-cli does not accept [UInt64] in any freaking capacity! Weirder, I have no problems in doing this is a test file with the Test.deployContract (check the test files. I've commented the deployments with this function where I can provide this array as argument). But since I'm unable to do this with flow.json and the "flow project deploy" or "flow accounts add-contract" commands, I have only two choices from here:
    1 - I need to switch the electionOptions argument to a String, provide something like "1;2;3;4" and then internally parse this to a [UInt64] - NOT IDEAL
    2 - I omit this argument from the constructor altogether and hard-code it in the contract. I do this by accepting a UInt64 argument as electionOptions instead, which should be the number of options available, and construct the [UInt64] internally using the InclusiveRange thing
    This is the current option I'm using because it has the least amount of headaches.

    I've opened a ticket with the Flow people to inform them about this issue. I'm unable to provide the damn [UInt64] in the deployments section of the flow.json. If I add an element such as 
    {
        "type": "Array",
        "value": [
            {
                "type": "UInt64",
                "value": "1"
            },
            {
                "type": "UInt64",
                "value": "2"
            },
            ...
        ]
    }
    the trick is to find <something> that flow-cli accepts. I've tried all combinations and then some and the thing just doesn't want any of that. It always complains of "expected JSON array, got..." and then a litany of things other than the ones I'm trying to do.
    This is clearly an issue with the JSON-Cadence parser and I would not be surprised if I was the first one to get it. Anyway, if this gets resolved sometime, I need to redo this constructor at some point.

    NOTE: Turns out the Flow developer dudes took my ticket seriously and did fixed the damn thing! I shouldn't be surprised, but I am. And it didn't took a whole year! Actually, it was surprisingly quick. Anyways, flow-cli released a new version (v2.2.10 @ 18/04/2025) and contract constructors accept arrays as arguments now! I've tested with an ExampleNFTContract and it works like a charm! I'm keeping this note here just to remind me that, sometimes, things do work out!
*/
    init(printLogs: Bool) {
        self.ballotPrinterAdminStoragePath = /storage/BallotPrinterAdmin
        self.ballotPrinterAdminPublicPath = /public/BallotPrinterAdmin
        self.ballotBoxStoragePath = /storage/BallotBox
        self.ballotBoxPublicPath = /public/BallotBox
        self.voteBoxStoragePath = /storage/VoteBox
        self.voteBoxPublicPath = /public/VoteBox
        self.ownerControlStoragePath = /storage/OwnerControl
        self.ownerControlPublicPath = /public/OwnerControl
        self.burnBoxStoragePath = /storage/BurnBox
        self.burnBoxPublicPath = /public/BurnBox

        // Set the default Ballot option to a nil value
        self.defaultBallotOption = nil

        self.printLogs = printLogs

        self.elections <- {}

        // Clean up storage and capabilities for all the resources that I need to create in this constructor
        let randomResource01: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.ballotPrinterAdminStoragePath)

        if (randomResource01 != nil) {
            log(
                "Found a type '"
                .concat(randomResource01.getType().identifier)
                .concat("' object in at ")
                .concat(self.ballotPrinterAdminStoragePath.toString())
                .concat(" path in account ")
                .concat(self.account.address.toString())
                .concat(" storage!")
            )
        }

        destroy randomResource01

        let oldCap01: Capability? = self.account.capabilities.unpublish(self.ballotPrinterAdminPublicPath)

        if (oldCap01 != nil) {
            log(
                "Found an active capability at "
                .concat(self.ballotPrinterAdminPublicPath.toString())
                .concat(" from account ")
                .concat(self.account.address.toString())
            )
        }

        let randomResource02: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.ballotBoxStoragePath)

        if (randomResource02 != nil) {
            log(
                "Found a type '"
                .concat(randomResource02.getType().identifier)
                .concat("' object in at ")
                .concat(self.ballotBoxStoragePath.toString())
                .concat(" path in account ")
                .concat(self.account.address.toString())
                .concat(" storage!")
            )
        }

        destroy randomResource02

        let oldCap02: Capability? = self.account.capabilities.unpublish(self.ballotBoxPublicPath)

        if (oldCap02 != nil) {
            log(
                "Found an active capability at "
                .concat(self.ballotBoxPublicPath.toString())
                .concat(" from account ")
                .concat(self.account.address.toString())
            )
        }

        let randomResource04: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.burnBoxStoragePath)

        if (randomResource04 != nil) {
            log(
                "Found a type '"
                .concat(randomResource04.getType().identifier)
                .concat("' object in at ")
                .concat(self.ownerControlStoragePath.toString())
                .concat(" path in account ")
                .concat(self.account.address.toString())
                .concat(" storage!")
            )
        }

        destroy randomResource04

        let oldCap04: Capability? = self.account.capabilities.unpublish(self.burnBoxPublicPath)

        if (oldCap04 != nil) {
            log(
                "Found an active capability at "
                .concat(self.burnBoxPublicPath.toString())
                .concat(" from account ")
                .concat(self.account.address.toString())
            )
        }

        // Process the BallotPrinterAdmin resource
        self.account.storage.save(<- create BallotPrinterAdmin(), to: self.ballotPrinterAdminStoragePath)

        let printerCapability: Capability<&VoteBooth.BallotPrinterAdmin> = self.account.capabilities.storage.issue<&VoteBooth.BallotPrinterAdmin> (self.ballotPrinterAdminStoragePath)

        self.account.capabilities.publish(printerCapability, at: self.ballotPrinterAdminPublicPath)

        // Repeat the process for the BallotBox
        self.account.storage.save(<- create BallotBox(), to: self.ballotBoxStoragePath)

        let BallotBoxCap: Capability<&VoteBooth.BallotBox> = self.account.capabilities.storage.issue<&VoteBooth.BallotBox>(self.ballotBoxStoragePath)

        self.account.capabilities.publish(BallotBoxCap, at: self.ballotBoxPublicPath)

        // Process the BurnBox as well
        self.account.storage.save(<- create BurnBox(), to: self.burnBoxStoragePath)

        let BurnBoxCap: Capability<&VoteBooth.BurnBox> = self.account.capabilities.storage.issue<&VoteBooth.BurnBox> (self.burnBoxStoragePath)
        self.account.capabilities.publish(BurnBoxCap, at: self.burnBoxPublicPath)

        emit VoteBooth.BallotBoxCreated(_accountAddress: self.account.address)
    }
}
// ----------------------------- CONSTRUCTOR END ---------------------------------------------------
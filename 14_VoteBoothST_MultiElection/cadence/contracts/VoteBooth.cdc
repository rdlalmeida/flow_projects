/*
    I'm killing two birds with one stone with this one. I came to the conclusion that the best approach for this system is not to have one contract per election (which would require deploying a new contract whenever a new election was needed, which would defeat the purpose of this system in the first place) but to have a easy way to create multiple elections with only one contract, like in a function or something of the sort. The obvious solution? To abstract elections as resources! It is surprising to see how useful linear types and resources are, especially in this context. Anyway, need requires a profound modification of the current contract. But since I'm moving in this direction, might as well take the opportunity to do the other thing that I wanted to do, which was to remove the NonFungibleToken standard requirement. No disrespect to Flow (on the contrary actually), but the NFT standard is actually making this worse than it needs to be. I mean, the standard was created to regulate digital collectibles, which is similar to what I want to do, but not quite enough for it to be useful to me. I now know enough of Cadence to make my own standards (which I will at some point...) as well as do this without one. So, lets roll the sleeves and get cracking...
*/
import "Burner"
import "BallotToken"
import "ElectionStandard"
import "BallotBurner"

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
    access(all) event ContractDataInconsistent(_ballotId: UInt64?, _owner: Address?)
    access(all) event VoteBoxCreated(_voterAddress: Address)
    access(all) event VoteBoxDestroyed(_ballotsInBox: Int, _ballotId: UInt64?)
    access(all) event BallotBoxCreated(_accountAddress: Address)
    access(all) event ElectionCreated(_electionId: UInt64)

    // This event is a duplicate from the similar one from the ElectionStandard module. I need to return this token in two cases and unfortunately I cannot import Events from other contracts.
    access(all) event NonNilResourceReturned(_resourceType: Type)

    // This event should emit when a Ballot is deposited in a BurnBox. NOTE: this doesn't mean that the Ballot was burned, it just set into an unrecoverable place where the Ballot is going to be burned at some point
    access(all) event BallotSetToBurn(_ballotId: UInt64, _voterAddress: Address)

    // CUSTOM ENTITLEMENTS
    access(all) entitlement BoothAdmin

    // CUSTOM VARIABLES
    // Election resources are going to be stored in their own dictionary. The key is the electionId, the value is the Election resource itself.
    // TODO: Getter and setter for Elections in this VotingBooth contract, as well as a "borrow" function to retrieve a 
    access(self) var elections: @{UInt64: {ElectionStandard.Election}}

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
    // TODO: Implement this one from the ElectionStandard interface
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
    /**
        This resource is the main point of interaction between voters and the voter framework. The VoteBox is a resource that can hold only one Ballot at a time per Election, i.e., per electionId. So, theoretically, this VoteBox can have multiple Ballots, but only one per electionId, which is fixed per Ballot.
    **/
    access(all) resource VoteBox: Burner.Burnable {
        /*
            I'm going to store Ballots in this dictionary where the UInt64 used as key is the Ballot's electionId. If another Ballot is submitted to storage with the same electionId, deal with it accordingly so that only one Ballot is allowed per Election.
        */
        access(self) var storedBallots: @{UInt64: {BallotToken.Ballot}}
        

        // Set the owner of this VoteBox at the constructor level to ensure that only this address can withdraw Ballots from it. Having this parameter covers the loophole in where the user loads this resource from storage (which makes self.owner == nil)
        access(self) let voteBoxOwner: Address
        
        /**
            Function to determine if a VoteBox already has a Ballot in it or not for the given electionId provided.

            @param: electionId (UInt64) The unique identifier of the Election resource in question.

            @return: Bool Returns a true if there's a Ballot stored in this VoteBox, a false otherwise.
        **/
        access(all) view fun hasBallot(electionId: UInt64): Bool {
            let ballotRef: &{BallotToken.Ballot}? = &self.storedBallots[electionId]

            if (ballotRef == nil) {
                return false
            }

            return true
        }

        /**
            This function stores a submitted Ballot in this VoteBox indexed to the Election resource associated to it. If a Ballot already exists in the position identified by the electionId, i.e., if a new Ballot was requested before the old one had been submitted, the new Ballot replaces the old one and the old one is sent to the BurnBox

            @param ballot(@{BallotToken.Ballot}) The Ballot resource to set in the internal storage for this resource.
        **/
        access(all) fun depositBallot(ballot: @{BallotToken.Ballot}) {
            // Each one of these boxes can only hold one vote of one type at a time. Validate this
            pre {
                // This pre-condition is everything really. It only allows the deposit of a Ballot if there are none stored yet. After storing one Ballot, it is impossible to deposit another one: this pre-condition stop this function for every self.storedBallots >= 1
                self.owner != nil: "Deposit is only allowed through a reference."
                
                // Ensure also that a Ballot with a different owner does not gets deposited. It should be impossible, given all the validations up to this point, but just in case
                self.owner!.address == ballot.ballotOwner: "Unable to deposit a Ballot with a different owner than the one in this VoteBox (".concat(self.owner!.address.toString()).concat(")")
            }

            // Store the address of the voteBoothDeployer from the Ballot to a variable for future use.
            let voteBoothDeployer: Address = ballot.voteBoothDeployer

            // Grab a reference to whatever may be stored in the electionId position in the storedBallots dictionary
            let randomRef: &AnyResource? = &self.storedBallots[ballot.electionId]

            // Test it and act accordingly
            if (randomRef == nil) {
                // If there was a nil in the electionId position, this is the first Ballot submitted for that particular election. This is the simple case
                // Proceed with storing the Ballot and destroying the older position, even though I'm 100% sure that it is a nil.
                let nilResource: @AnyResource? <- self.storedBallots[ballot.electionId] <- ballot

                destroy nilResource


            }
            else if (randomRef.getType() == Type<&{BallotToken.Ballot}?>()) {
                // In this case, there's an old Ballot in this position. Retrieve it and send it to the BurnBox
                let currentElectionId: UInt64 = ballot.electionId
                let voteBoxDeployer: Address = ballot.voteBoothDeployer

                let oldBallot: @{BallotToken.Ballot}? <- self.storedBallots[currentElectionId] <- ballot

                if (oldBallot == nil) {
                    panic(
                        "ERROR: Unable to retrieve the old Ballot set in position ".concat(currentElectionId.toString())
                        .concat(" for account ")
                        .concat(self.owner!.address.toString())
                    )
                }

                // Grab a reference to the BurnBox
                let burnBoxRef: &{BallotBurner.BurnBox} = getAccount(voteBoothDeployer).capabilities.borrow<&{BallotBurner.BurnBox}>(VoteBooth.burnBoxPublicPath) ??
                panic(
                    "Unable to get a valid &{BallotBurner.BurnBox} at "
                    .concat(VoteBooth.burnBoxPublicPath.toString())
                    .concat(" for account ")
                    .concat(voteBoothDeployer.toString())
                )

                // Deposit the old Ballot into the BurnBox
                burnBoxRef.depositBallotToBurn(ballotToBurn: <- oldBallot!)

            }
            else {
                // Last case is that something does exist in the electionId position, but it is not an older Ballot (it's something else...)
                // Emit the relevant events but proceed as normal
                let nonNilResource: @AnyResource? <- self.storedBallots[ballot.electionId] <- ballot

                emit NonNilResourceReturned(_resourceType: nonNilResource.getType())

                // Nothing more left to do but to destroy this nonNilResource
                destroy nonNilResource

            }
        }
        

        /**
            Function to retrieve the address set as the Ballot owner, if any exists.

            @return: Address Function returns this Ballot's owner address, if there's one set. Otherwise returns a nil
        **/
        access(all) fun getBallotOwner(): Address? {
            // This one becomes super easy with the structure I'm using
            return self.storedBallotOwner
        }

        /**
            Function to return the ballotId associated to the current Ballot, if there's one stored in this VoteBox. NOTE: If this function returns a nil, it means that this VoteBox is empty, not that there's a Ballot with a nil as ballotId. That should be impossible.

            @return: UInt64? If there's a Ballot stored in this VoteBox, this function returns a UInt64 corresponding to its ballotId. Otherwise (there's no Ballot stored yet) returns a nil.
        **/
        access(all) view fun getBallotId(): UInt64? {
            // And this one too
            return self.storedBallotId
        }

        /**
            Default function to be called whenever I destroy one of these VoteBoxes using the Burner contract. IMPORTANT: For this to work, I need to use the Burner contract to destroy any VoteBoxes. If I simply use the 'destroy' function, this function is not called!
        **/
        access(contract) fun burnCallback(): Void {
            // Prepare this to emit the VoteBoxDestroyed event, namely, check if there's any Ballot stored, and if it is, grab its Id first
            let ballotId: UInt64? = self.storedBallotId

            // If the ballotId is not nil, do this properly and burn the Ballot before finishing
            if (ballotId != nil) {
                let ballotToBurn: @{BallotToken.Ballot} <- self.storedBallot.remove(key: ballotId!)!


                // Even though this resource is about to be destroyed, I'm super prickly with everything. Just to be consistent with the awesome programmer that I am, set the internal storedBallotOwner and storedBallotId to nil. It's pointless, but that how I roll
                self.storedBallotId = nil
                self.storedBallotOwner = nil

                /*
                    In order to properly destroy (burn) any Ballot still in storage, send it to the VoteBooth deployer's BurnBox instead. At this level, this resource is unable to access the OwnerControl resource (only this deployer can do that) to maintain contract data consistency, i.e., to remove the respective entries from the internal dictionaries and such. Sending this Ballot to the BurnBox, which I can get from this resource because the reference to it is publicly accessible, solves all these problems. As such, I've set the contract deployer address, as in the address associated with the ballotPrinterAdmin resource required to mint the Ballot in the first place, as a access(all) parameter in the Ballot resource. Do it
                */
                let burnBoxRef: &{BallotBurner.BurnBox} = getAccount(ballotToBurn.voteBoothDeployer).capabilities.borrow<&{BallotBurner.BurnBox}>(VoteBooth.burnBoxPublicPath) ??
                panic(
                    "Unable to retrieve a valid &VoteBooth.BurnBox at "
                    .concat(VoteBooth.burnBoxPublicPath.toString())
                    .concat(" from account ")
                    .concat(ballotToBurn.voteBoothDeployer.toString())
                )

                // Before depositing the Ballot into the BurnBox reference, grab a reference to the Election reference associated to this Ballot and decrement the number of minted Ballots in that Election, given that, once the Ballot is there, it's pretty much already destroyed. Also, I need to avoid circular references and, as such, cannot import this contract from the BallotBurner contract (to access the VoteBooth.election dictionary), so I need to do this here.
                let electionRef: &{ElectionStandard.Election}? = VoteBooth.borrowElection(electionId: ballotToBurn.electionId)

                // If the reference above comes back as a nil, don't sweat it. It can be because the Election was processed in the meantime and this VoteBox still had a Ballot for it. Just move on if that is the case
                // TODO:

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
            let storedBallotRef: auth(BallotToken.TallyAdmin) &{BallotToken.Ballot}? = &self.storedBallot[self.storedBallotId!]

            // Just to be sure, check if the reference obtained is not nil. Panic if, by some reason, it is
            if (storedBallotRef == nil) {
                panic(
                    "Unable to get a valid &{BallotToken.Ballot} for ballotId "
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
            self.storedBallots <- {}
            self.voteBoxOwner = ownerAddress
        }
    }
// ----------------------------- VOTE BOX END ------------------------------------------------------

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
    access(all) view fun borrowElection(electionId: UInt64): &{ElectionStandard.Election}? {
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
/**
    I'm killing two birds with one stone with this one. I came to the conclusion that the best approach for this system is not to have one contract per election (which would require deploying a new contract whenever a new election was needed, which would defeat the purpose of this system in the first place) but to have a easy way to create multiple elections with only one contract, like in a function or something of the sort. The obvious solution? To abstract elections as resources! It is surprising to see how useful linear types and resources are, especially in this context. Anyway, need requires a profound modification of the current contract. But since I'm moving in this direction, might as well take the opportunity to do the other thing that I wanted to do, which was to remove the NonFungibleToken standard requirement. No disrespect to Flow (on the contrary actually), but the NFT standard is actually making this worse than it needs to be. I mean, the standard was created to regulate digital collectibles, which is similar to what I want to do, but not quite enough for it to be useful to me. I now know enough of Cadence to make my own standards (which I will at some point...) as well as do this without one. So, lets roll the sleeves and get cracking...
**/
import "Burner"
import "BallotStandard"
import "ElectionStandard"
import "BallotBurner"

access(all) contract VoteBooth {
    // STORAGE PATHS
    access(all) let ballotPrinterAdminStoragePath: StoragePath
    access(all) let ballotPrinterAdminPublicPath: PublicPath
    access(all) let voteBoxStoragePath: StoragePath
    access(all) let voteBoxPublicPath: PublicPath
    access(all) let burnBoxStoragePath: StoragePath
    access(all) let burnBoxPublicPath: PublicPath

    // CUSTOM EVENTS
    access(all) event ContractDataInconsistent(_ballotId: UInt64?, _owner: Address?)
    access(all) event VoteBoxCreated(_voterAddress: Address)
    access(all) event VoteBoxDestroyed(_ballotsInBox: Int, _ballotIds: [UInt64])

    // Event for when a new Election resource is created.
    access(all) event ElectionCreated(_electionId: UInt64)

    access(all) event BallotMinted(_ballotId: UInt64, _voterAddress: Address, _electionId: UInt64)

    // This event is a duplicate from the similar one from the ElectionStandard module. I need to return this token in two cases and unfortunately I cannot import Events from other contracts.
    access(all) event NonNilResourceReturned(_resourceType: Type)

    // CUSTOM ENTITLEMENTS
    access(all) entitlement BoothAdmin

    // CUSTOM VARIABLES
    // Election resources are going to be stored in their own dictionary. The key is the electionId, the value is the Election resource itself.
    // TODO: Getter and setter for Elections in this VotingBooth contract, as well as a "borrow" function to retrieve a 
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
access(all) resource Election: ElectionStandard.Election, Burner.Burnable {
    access(all) let _name: String
    access(all) let _ballot: String
    access(all) let _options: [UInt8]

    access(contract) let electionId: UInt64
    access(contract) var totalBallotsMinted: UInt
    access(contract) var totalBallotsSubmitted: UInt

    access(all) let _defaultBallotOption: UInt8?

    access(contract) var submittedBallots: @{Address: {BallotStandard.Ballot}}

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
    access(all) resource Ballot: BallotStandard.Ballot {
        /// The main token id, issued by Flow's internal uuid function
        access(all) let ballotId: UInt64

        /// The main option to represent the choice. A nil indicates none selected yet
        access(BallotStandard.VoteEnable | BallotStandard.TallyAdmin) var option: UInt8?

        /// The address to the VoteBooth contract deployer. This is useful to be able to retrieve references to deployer bound resources through accessing public capabilities.
        access(all) let voteBoothDeployer: Address

        /// The id of the Election resource that this Ballot is associated with.
        access(all) let electionId: UInt64

        access(all) let defaultBallotOption: UInt8?

        access(all) var ballotOwner: Address?

        /**
            Function that uses this Ballot's electionId, which points to a valid @VoteBooth.Election resource, to get a reference to the Election resource and then use that resource to retrieve the election name.

            @return: String Returns the name of the election resource associated with this Ballot.
        **/
        access(all) view fun getElectionName(): String {

            let electionRef: &{ElectionStandard.Election}? = VoteBooth.borrowElection(electionId: self.electionId)

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
            let electionRef: &{ElectionStandard.Election}? = VoteBooth.borrowElection(electionId: self.electionId)

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
            let electionRef: &{ElectionStandard.Election}? = VoteBooth.borrowElection(electionId: self.electionId)

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
    /**
        This resource is the main point of interaction between voters and the voter framework. The VoteBox is a resource that can hold only one Ballot at a time per Election, i.e., per electionId. So, theoretically, this VoteBox can have multiple Ballots, but only one per electionId, which is fixed per Ballot.
    **/
    access(all) resource VoteBox: Burner.Burnable {
        /*
            I'm going to store Ballots in this dictionary where the UInt64 used as key is the Ballot's electionId. If another Ballot is submitted to storage with the same electionId, deal with it accordingly so that only one Ballot is allowed per Election.
        */
        access(self) var storedBallots: @{UInt64: {BallotStandard.Ballot}}
        

        // Set the owner of this VoteBox at the constructor level to ensure that only this address can withdraw Ballots from it. Having this parameter covers the loophole in where the user loads this resource from storage (which makes self.owner == nil)
        access(self) let voteBoxOwner: Address
        
        /**
            Function to determine if a VoteBox already has a Ballot in it or not for the given electionId provided.

            @param: electionId (UInt64) The unique identifier of the Election resource in question.

            @return: Bool Returns a true if there's a Ballot stored in this VoteBox, a false otherwise.
        **/
        access(all) view fun hasBallot(electionId: UInt64): Bool {
            let ballotRef: &{BallotStandard.Ballot}? = &self.storedBallots[electionId]

            if (ballotRef == nil) {
                return false
            }

            return true
        }

        /**
            This function stores a submitted Ballot in this VoteBox indexed to the Election resource associated to it. If a Ballot already exists in the position identified by the electionId, i.e., if a new Ballot was requested before the old one had been submitted, the new Ballot replaces the old one and the old one is sent to the BurnBox

            @param ballot(@{BallotStandard.Ballot}) The Ballot resource to set in the internal storage for this resource.
        **/
        access(all) fun depositBallot(ballot: @{BallotStandard.Ballot}) {
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
            else if (randomRef.getType() == Type<&{BallotStandard.Ballot}?>()) {
                // In this case, there's an old Ballot in this position. Retrieve it and send it to the BurnBox
                let currentElectionId: UInt64 = ballot.electionId
                let voteBoxDeployer: Address = ballot.voteBoothDeployer

                let oldBallot: @{BallotStandard.Ballot}? <- self.storedBallots[currentElectionId] <- ballot

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
            Function to retrieve the address set as the Ballot owner, if any exists, for the electionId provided. The obvious expectation is that every Ballot in storage has the same owner.
            NOTE: It's possible to receive a nil as return for this function if, by whatever reason, the Ballot was previously anonymised.

            @param electionId (UInt64) The id of the election whose Ballot owner is to be returned. 

            @return: Address Function returns this Ballot's owner address, if there's one set. Otherwise returns a nil
        **/
        access(all) fun getBallotOwner(electionId: UInt64): Address? {
            let ballotRef: &{BallotStandard.Ballot}? = &self.storedBallots[electionId]

            if (ballotRef == nil) {
                return nil
            }

            return ballotRef!.ballotOwner
        }

        /**
            Function to return the ballotId associated to the Ballot associated to the electionId provided. NOTE: If this function returns a nil, it means that this VoteBox is empty, not that there's a Ballot with a nil as ballotId. That should be impossible.

            @return: UInt64? If there's a Ballot stored in this VoteBox, this function returns a UInt64 corresponding to its ballotId. Otherwise (there's no Ballot stored yet) returns a nil.
        **/
        access(all) view fun getBallotId(electionId: UInt64): UInt64? {
            // Same process as before
            let ballotRef: &{BallotStandard.Ballot}? = &self.storedBallots[electionId]

            if (ballotRef == nil) {
                return nil
            }

            return ballotRef!.ballotId
        }

        /**
            Default function to be called whenever I destroy one of these VoteBoxes using the Burner contract. Basically, this function "empties" the VoteBox by sending any Ballots still in storage to a BurnBox.            
            
            IMPORTANT: For this to work, I need to use the Burner contract to destroy any VoteBoxes. If I simply use the 'destroy' function, this function is not called!
        **/
        access(contract) fun burnCallback(): Void {
            // Grab a list of the keys for the storedBallots internal dictionary. Each corresponds to an electionId
            let electionIds: [UInt64] = self.storedBallots.keys

            // I need an array to store the ballotIds of the Ballots set to burn
            var ballotsToBurnIds: [UInt64] = []

            // Grab a reference to the BurnBox as well, but do so only if there are Ballots to be burned
            if (electionIds.length > 0) {
                // There are Ballots that need to be sent to the BurnBox. Grab a reference to it. I need on of the Ballots for it
                let ballotRef: &{BallotStandard.Ballot}? = &self.storedBallots[electionIds[electionIds.length - 1]]

                // Just to be sure, make sure a valid reference was retrieved
                if (ballotRef == nil) {
                    panic(
                        "ERROR: Unable to get a valid &{BallotStandard.Ballot} for electionId "
                        .concat(electionIds[electionIds.length - 1].toString())
                        .concat(" for account ")
                        .concat(self.owner!.address.toString())
                    )
                }

                let voteBoothDeployer: Address = ballotRef!.voteBoothDeployer

                let burnBoxRef: &{BallotBurner.BurnBox} = getAccount(voteBoothDeployer).capabilities.borrow<&{BallotBurner.BurnBox}>(VoteBooth.burnBoxPublicPath) ??
                panic(
                    "Unable to retrieve a valid &{BallotBurner.BurnBox} at "
                    .concat(VoteBooth.burnBoxPublicPath.toString())
                    .concat(" for account ")
                    .concat(self.owner!.address.toString())
                )

                // All ready. Loop over all the existing Ballots and deposit them in the BurnBox

                for electionId in electionIds {
                    let currentBallot: @{BallotStandard.Ballot}? <- self.storedBallots.remove(key: electionId)

                    // Don't bother if the currentBallot is a nil
                    if (currentBallot != nil) {
                        let currentBallotId: UInt64 = currentBallot?.ballotId!

                        // Save this Ballot's ballotId
                        ballotsToBurnIds.append(currentBallotId)
                        burnBoxRef.depositBallotToBurn(ballotToBurn: <- currentBallot!)
                    }
                    else {
                        // For consistency reasons, I need to destroy the nil value as well
                        destroy currentBallot
                    }
                }
            }

            // Once the last step is done, all Ballots were properly processed. All there's left to do is to emit the respective Events
            emit VoteBoxDestroyed(_ballotsInBox: ballotsToBurnIds.length, _ballotIds: ballotsToBurnIds)
        }

        /**
            NOTE: This function is for TEST and DEBUG purposes only.
            This function returns the current option in a Ballot stored internally, or nil if there are none.
            I've set the protections to prevent people other than the owner in the Ballot resource itself. If someone else tries to fetch the current vote other than the Ballot owner (which is also the VoteBox owner by obvious reasons), it fails a pre condition and panics. If there are no Ballots yet in the VoteBox for the electionId provided, a nil is returned instead.
            TODO: Delete or protect this function with a proper entitlement before moving this to PROD

            @param electionId (UInt64) The electionId parameter that identifies the election whose vote is to be returned, if exists.

            @return UInt8? The option selected (or lack of one) for a Ballot submitted under the provided Election
        **/
        access(BallotStandard.TallyAdmin) fun getCurrentVote(electionId: UInt64): UInt8? {
            // Grab the id for the Ballot in storage, if any
            if (self.storedBallots.length == 0) {
                // If there are no Ballots stored yet, return a nil
                return nil
            }
            
            // Grab a reference to the ballot stored
            let storedBallotRef: auth(BallotStandard.TallyAdmin) &{BallotStandard.Ballot}? = &self.storedBallots[electionId]

            // Check if the reference returned is a nil, which means that no Ballot was yet submitted for the electionId provided
            if (storedBallotRef == nil) {
                // Send back a nil in this case as well
                return nil
            }

            // A valid Ballot was found if I get to this point in the code. Validate that the ballotOwner and the current owner of this VoteBox match. Panic if not
            if(self.voteBoxOwner != storedBallotRef!.ballotOwner) {
                panic(
                    "ERROR: The Ballot stored for the election with Id "
                    .concat(electionId.toString())
                    .concat(" has owner ")
                    .concat(storedBallotRef!.ballotOwner!.toString())
                    .concat(" while this VoteBox has owner ")
                    .concat(self.voteBoxOwner.toString())
                    .concat(". These two need to match!")
                )
            }

            // Invoke the function from the ballot reference itself.
            return storedBallotRef!.getVote()
        }

        /**
            This is the function used to cast a vote. It does an abnormal number of (somewhat redundant) validations before allowing the user to cast a vote. The function receives the option to set in the Ballot, if one exists, which includes the possibility of providing the defaultBallotOption, which makes the Ballot into a revoke one.

            @param: electionId (UInt64) The id of the Election to check for Ballots in storage.
            @param: option (UInt8?) The option to set in the Ballot, if it exists.
        **/
        access(BallotStandard.VoteEnable) fun castVote(electionId: UInt64, option: UInt8?): Void {
            pre {
                self.owner != nil: "Voting is only allowed through an authorized reference!"
                self.storedBallots.length > 0: "Account ".concat(self.owner!.address.toString()).concat(" does not have a Ballot in storage to vote!")
            }

            post {
                before(self.storedBallots.length) == self.storedBallots.length: "This function should not change the number of Ballots in storage!"
            }

            // Get a reference to the stored Ballot under the electionId provided.
            let storedBallotRef: auth(BallotStandard.VoteEnable) &{BallotStandard.Ballot}? = &self.storedBallots[electionId]

            // If the reference comes back as a nil, it means that no Ballot exists for the electionId provided.
            if (storedBallotRef == nil) {
                panic(
                    "ERROR: No Ballots found in storage for the electionId ("
                    .concat(electionId.toString())
                    .concat(") provided for a VoteBox from account ")
                    .concat(self.voteBoxOwner.toString())
                )
            }
            else if (self.voteBoxOwner != storedBallotRef!.ballotOwner) {
                // In this branch, the Ballot reference is not nil, but the owner from the Ballot and the one from this VoteBox does not match. That's a panic as well
                panic(
                    "ERROR: The owner of this VoteBox ("
                    .concat(self.voteBoxOwner.toString())
                    .concat(") does not matches the owner set in the Ballot (")
                    .concat(storedBallotRef!.ballotOwner!.toString())
                    .concat(") for election with Id ")
                    .concat(electionId.toString())
                )
            }

            // All is OK so far. Do it.
            storedBallotRef!.vote(newOption: option)            
        }

        /**
            This function sets the Ballot to be tallied at a later stage. This, essentially, amounts at submitting the Ballot into the Election resource identified by the electionId provided.

            @param: electionId (UInt64) The election identifier for the Election resource to submit a Ballot currently in storage.
        **/
        access(BallotStandard.VoteEnable) fun submitBallot(electionId: UInt64): Void {
            // Make sure that everything is correct for submit the Ballot
            pre {
                self.owner != nil: "Ballots can only be submitted from an authorized reference!"
                self.storedBallots.length > 0: "No Ballots stored in the VoteBox for account ".concat(self.owner!.address.toString())
            }

            post {
                // Check that the VoteBox was reset after submission
                self.storedBallots[electionId] == nil: "The Ballot was not properly submitted for election ".concat(electionId.toString()).concat("!")
            }
        
            // All good. Grab the Ballot in storage
            let ballotToSubmit: @{BallotStandard.Ballot} <- self.storedBallots.remove(key: electionId) ??
            // Panic immediately if I didn't get a valid reference back
            panic(
                "Unable to load a valid  @{BallotStandard.Ballot} for a VoteBox in account "
                .concat(self.owner!.address.toString())
                .concat(" for election with Id ")
                .concat(electionId.toString())
            )

            // Use the voteBoothDeployer address to retrieve a reference to the Election resource to where the Ballot is to be submitted
            let voteBoothDeployerAccount: Address = ballotToSubmit.voteBoothDeployer
            
            let electionRef: &{ElectionStandard.Election} = VoteBooth.borrowElection(electionId: electionId) ??
            panic(
                "ERROR: Unable to retrieve a valid &{ElectionStandard.Election} with Id "
                .concat(electionId.toString())
                .concat(" for account ")
                .concat(voteBoothDeployerAccount.toString())
            )

            // And that's pretty much it. Submit the ballot and get on with it. The submission function deals with all the parameter manipulation.
            electionRef.submitBallot(ballot: <- ballotToSubmit)
        }

        init(ownerAddress: Address) {
            self.storedBallots <- {}
            self.voteBoxOwner = ownerAddress
        }
    }
// ----------------------------- VOTE BOX END ------------------------------------------------------

// ----------------------------- BURN BOX BEGIN ----------------------------------------------------
// Local implementation of the BurnBox
access(all) resource BurnBox: BallotBurner.BurnBox, Burner.Burnable {
    access(contract) var ballotsToBurn: @{UInt64: {BallotStandard.Ballot}}

    init() {
        self.ballotsToBurn <- {}
    }
}
// ----------------------------- BURN BOX END ------------------------------------------------------

// ----------------------------- BALLOT PRINTER BEGIN ----------------------------------------------
/**
    To protect the most sensible functions of the BallotPrinterAdmin resource, namely the printBallot function, I'm protecting it with a custom 'BoothAdmin' entitlement defined at the contract level.
    This means that, in order to have the 'printBallot' and 'sot' available in a &BallotPrinterAdmin, I need an authorized reference instead of a normal one.
    Authorized references are indicated with a 'auth(VoteBooth.BoothAdmin) &VoteBooth.BallotPrinterAdmin' and these can only be successfully obtained from the 'account.storage.borrow<auth(VoteBooth.BoothAdmin) &VoteBooth.BallotPrinterAdmin>(PATH)', instead of the usual 'account.capabilities.borrow...'
    Because I now need to access the 'storage' subset of the Flow API, I necessarily need to obtain this reference from the transaction signer and no one else! The transaction need to be signed by the deployed to work! Cool, that's exactly what I want!
    It is now impossible to call the 'printBallot' function from a reference obtained by the usual, capability-based reference retrievable by a simple account reference, namely, from 'let account: &Account = getAccount(accountAddress)'

    NOTE: VERY IMPORTANT
    This resource can only be used as a reference, never directly as a resource!!
    In other words, never load this, use it, and then put it back into storage. Because, not only it is extremely inefficient from the blockchain point of view, but most importantly, the resource is "dangling" and, as such, the self.owner!.address is going to break this due to the fact that self.owner == nil! This resource relies A LOT in knowing who the owner of the resource is, so one more reason to avoid this.
**/
    access(all) resource BallotPrinterAdmin {
        /**
            Function to create a new Ballot. Each Ballot cannot exist by themselves, they need to be associated to an Election resource identified by the electionId. This function, due to its importance, validates if the electionId provided has a valid Election object in this account's storage (because all the individual Election resources are stored under the VoteBooth contract) and panics if the Election in question does not exists.

            @param: voterAddress (Address) The account address of the voter that is to receive this Ballot.
            @param: electionId (UInt64) The identifier of the Election resource that this Ballot is to be associated to.

            @return (@{BallotStandard.Ballot}) a Ballot resource associated to a specific voterAddress and an Election resource. 
        **/
        access(BoothAdmin) fun printBallot(voterAddress: Address, electionId: UInt64): @{BallotStandard.Ballot} {
            pre {
                // First, ensure that the contract owner (obtainable via self.owner!.address) does not match the address provided.
                self.owner!.address != voterAddress: "The contract owner is not allowed to vote!"
            }

            // Validate that the electionId provided has a valid Election backing it up.
            let electionRef: &{ElectionStandard.Election} = VoteBooth.borrowElection(electionId: electionId) ??
            // If the borrow function returns a nil, don't waste anytime and panic immediately
            panic(
                "ERROR: Unable to retrieve a valid &{ElectionStandard.Election} for electionId "
                .concat(electionId.toString())
                .concat(" in the VoteBooth contract in account ")
                .concat(self.owner!.address.toString())
                .concat(". Cannot mint a new Ballot without a valid Election created first!")
            )

            let newBallot: @{BallotStandard.Ballot} <- create Ballot(_ballotOwner: voterAddress, _voteBoothDeployer: self.owner!.address, _electionId: electionId)

            // Increment the total Ballots associated to the Election whose reference I already have to account for the new Ballot just created
            electionRef.incrementTotalBallotsMinted(ballots: 1)

            // Emit the BallotMinted event
            emit BallotMinted(_ballotId: newBallot.ballotId, _voterAddress: voterAddress, _electionId: electionId)
            
            // All done. Return the new Ballot
            return <- newBallot
        }

        /**
            Function to destroy a Ballot provided as argument using the Burner contract, therefore triggering the burnCallback function from the BallotStandard.Ballot standard. Destroying the Ballot using this function adjusts the ballot totals in the Election resource associated to the Ballot to destroy, if any.

            @param: ballotToBurn (@{BallotStandard.Ballot}) The Ballot resource to destroy.
        **/
        access(BoothAdmin) fun burnBallot(ballotToBurn: @{BallotStandard.Ballot}): Void {
            // Grab a reference to an Election resource and check if it is a valid (non-nil) one. If so, decrement the total Ballots minted from it.
            let electionRef: &{ElectionStandard.Election}? = VoteBooth.borrowElection(electionId: ballotToBurn.electionId)

            // There is a non-zero probability that the Election may not exist anymore at the point where this Ballot is being destroyed. As such, test if the reference is a nil and decrement the total ballots minted (not the submitted ones) from it. If it is a nil, forget about it
            if (electionRef != nil) {
                electionRef!.decrementTotalBallotsMinted(ballots: 1)
            }

            // Destroy (burn) the Ballot finally using the Burner contract.
            Burner.burn(<- ballotToBurn)
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
        NOTE: I need to restrict the access to Election resources for (obvious)security reasons. For now I'm restricting the borrowing of Election to 'access(account)' but I need to test this thoroughly to be 100% sure there are no leaks.

        @param: electionId (UInt64) The unique identifier for the @VoteBooth.Election resource to retrieve.
        
        @return: &VoteBooth.Election? If a @VoteBooth.Election exists for the electionId provided, this function returns a reference to it. Otherwise a nil is returned instead.
    **/
    access(account) view fun borrowElection(electionId: UInt64): &{ElectionStandard.Election}? {
        return &self.elections[electionId]
    }

    /**
        Creates a new Election resource configured with the parameters provided as arguments. This function is protected with an 'access(account)' modifier, so only the deployer of this VoteBooth contract can create new Election resources.
        This function does not return the VoteBooth.Election resource created but instead stores it into this contract internal 'elections' dictionary using the automatically generated electionId as key.
        @param: electionName (String) The name of this election.
        @param: electionBallot (String) The ballot with the question to pose to voters.
        @param: electionOption ([UInt8]) The array of available options to select.
        @emit: (VoteBooth.ElectionCreated) If the Election resource is successfully created, this function emits the ElectionCreated event.
    **/
    access(account) fun createElection(electionName: String, electionBallot: String, electionOptions: [UInt8]): Void {
        let newElection: @VoteBooth.Election <- create VoteBooth.Election(name: electionName, ballot: electionBallot, options: electionOptions)

        let newElectionId: UInt64 = newElection.electionId

        // Save the election in the internal dictionary
        let randomResource: @AnyResource? <- self.elections[newElectionId] <- newElection

        // Emit the ElectionCreated event
        emit VoteBooth.ElectionCreated(_electionId: newElectionId)

        // Test the randomResource obtained and act accordingly
        if (randomResource != nil) {
            // Somehow there a non-nil resource stored in the electionId key of the elections dictionary. Not a lot I can do but to emit the NonNilResourceReturned event and move on
            emit VoteBooth.NonNilResourceReturned(_resourceType: randomResource.getType())
        }

        // But destroy the randomResource nonetheless
        destroy randomResource
    }
    
    /**
        Simple function to obtain an array with all the electionId for the Election resources created and stored internally in the 'elections' dictionary.
        @return: [UInt64] An array with all the stored electionId for all the active elections.
    **/
    access(all) view fun getElectionIds(): [UInt64] {
        return self.elections.keys
    }

    /**
        Function to destroy an existing Election currently save in the 'elections' internal dictionary. The function requires an electionId that need to correspond to a specific Election resource in storage. If successful, this function emits the ElectionDestroyed event.
        The function is 'access(account)' protected so that only the VoteBooth contract deployer can run it.
        @param: electionId (UInt64) The election identifier for the Election resource to destroy.
        @emit: ElectionStandard.ElectionDestroyed The event signaling the destruction of an Election resource with the electionId indicated, as well as with the total number of submitted Ballots in it, as in, the Ballots that were submitted with a valid option.
    **/
    access(account) fun destroyElection(electionId: UInt64): Void {
        // Check if the election in question exists. If so, continue. If not, no biggie, there's no need to panic over not being able to destroy an Election that does not exist anyway
        let electionToDestroy: @VoteBooth.Election? <- self.elections.remove(key: electionId)

        // Use the Burner contract to destroy the Election resource so that it runs the burnCallback function. If this variable is actually a nil, don't fret about it. The Burner is more than able to deal with it.
        Burner.burn(<- electionToDestroy)
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
        self.voteBoxStoragePath = /storage/VoteBox
        self.voteBoxPublicPath = /public/VoteBox
        self.burnBoxStoragePath = /storage/BurnBox
        self.burnBoxPublicPath = /public/BurnBox

        // Set the default Ballot option to a nil value
        self.defaultBallotOption = nil

        self.printLogs = printLogs

        self.elections <- {}

        // Clean up storage and capabilities for all the resources that I need to create in this constructor. First one: the ballotPrinterAdmin
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

        // Repeat the process for the BurnBox
        let randomResource02: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.burnBoxStoragePath)

        if (randomResource02 != nil) {
            log(
                "Found a type '"
                .concat(randomResource02.getType().identifier)
                .concat("' object in at ")
                .concat(self.burnBoxStoragePath.toString())
                .concat(" path in account ")
                .concat(self.account.address.toString())
                .concat(" storage!")
            )
        }

        destroy randomResource02

        let oldCap02: Capability? = self.account.capabilities.unpublish(self.burnBoxPublicPath)

        if (oldCap02 != nil) {
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

        // Process the BurnBox as well
        self.account.storage.save(<- create BurnBox(), to: self.burnBoxStoragePath)

        let BurnBoxCap: Capability<&VoteBooth.BurnBox> = self.account.capabilities.storage.issue<&VoteBooth.BurnBox> (self.burnBoxStoragePath)
        self.account.capabilities.publish(BurnBoxCap, at: self.burnBoxPublicPath)
    }
}
// ----------------------------- CONSTRUCTOR END ---------------------------------------------------
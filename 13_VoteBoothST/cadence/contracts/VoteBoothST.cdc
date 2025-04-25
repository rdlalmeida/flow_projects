/*
    This contract is just a cleaner, more efficient (and hopefully functional) version of the VoteBooth contract. As usual, I've wrote 98% of the last attempt at this contract in one sitting, hoping that by taking care of all the issues revealed by VS code would be enough. After wasting weeks writing a smart contract with almost 1000 lines (a lot of those are these very long comments I'm so prone to write), I found out that my stupid v.12 contract does everything... except storing Ballots in VoteBoxes!!! Which is, like, one of the most import steps of this process!

    I did try to debug this thing for a while, but it is just too much... My best approach is to re-write this thing from scratch and test it thoroughly as much as possible, just to make sure that this contract continues working as supposed.
*/

import "NonFungibleToken"
import "Burner"

access(all) contract VoteBoothST: NonFungibleToken {
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
    access(all) event BallotMinted(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotSubmitted(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotModified(_oldBallotId: UInt64, _newBallotId: UInt64, _voterAddress: Address)
    access(all) event BallotBurned(_ballotId: UInt64?, _voterAddress: Address?)
    access(all) event BallotRevoked(_ballotId: UInt64?, _voterAddress: Address)
    access(all) event ContractDataInconsistent(_ballotId: UInt64?, _owner: Address?)
    access(all) event VoteBoxCreated(_voterAddress: Address)
    access(all) event VoteBoxDestroyed(_ballotsInBox: Int, _ballotId: UInt64?)
    access(all) event BallotBoxCreated(_accountAddress: Address)
    // This event should emit when a Ballot is deposited in a BurnBox. NOTE: this doesn't mean that the Ballot was burned, it just set into an unrecoverable place where the Ballot is going to be burned at some point
    access(all) event BallotSetToBurn(_ballotId: UInt64, _voterAddress: Address)

    // TODO: Complete this one also. I'm not emitting this one
    /*
        I've created this custom event to be emitted whenever I failed to deposit a valid Ballot in a VoteBox. This can happen for a bunch of reasons, hence why I added the '_reason' input field for that purpose. This is an Int value that indicated the motive behind this event, namely:

        0 - All is OK. This is the default code.
        1 - Unable to retrieve a valid VoteBox
        2 - VoteBox already has a Ballot in it
        3 - The VoteBox is empty but the 'owners' dictionary has an entry for the current address
        4 - The VoteBox is empty but the 'ballotIds' dictionary has an entry for the current ballotId
    */
    access(all) event BallotNotDelivered(_voterAddress: Address, _reason: Int)

    // CUSTOM ENTITLEMENTS
    access(all) entitlement BoothAdmin

    // TODO: This entitlement is a temporary thing and needs to be replaced by a similar entitlement but specified in the Tally contract (to be done in the future). I'm using this one just to prevent the admin user from being able to withdraw ballots from the Ballot Box
    access(all) entitlement TallyAdmin

    /*
        This entitlement serves to restrict the function 'vote' from the VoteBox resource to be available only through an authorized reference. This means that even if someone, somehow, is able to withdraw the Ballot and its now 'dangling', i.e., not in any storage, this function is not available, as well as through an unauthorized reference to the VoteBox. In order to be able to vote, an authorized reference needs to be obtained, and that means access to the user storage, and that means a signed transaction by the owner of the said storage. In other words, this entitlement prevents anyone other than the owner (and even he/she can only vote through an authorized reference to his/her own VoteBox reference) to vote
    */
    access(all) entitlement VoteEnable

    // CUSTOM VARIABLES
    access(all) let _name: String
    access(all) let _symbol: String
    access(all) let _ballot: String
    access(all) let _location: String
    access(all) let _options: [UInt8]

    // I'm using these to do an internal tracking mechanism to protect this against double voting and the like
    access(account) var totalBallotsMinted: UInt64
    access(account) var totalBallotsSubmitted: UInt64

    // I'm setting the default Ballot option as a variable for easier comparison
    access(all) let defaultBallotOption: UInt8

    // Use this variable set (the contract constructor receives an argument to set it) to enable or disable the printing of logs in this project
    access(all) let printLogs: Bool

// ----------------------------- BALLOT BEGIN ------------------------------------------------------
    /*
        This is the main actor in this process. The Ballot NFT is issued on demand, is editable by the voter, and can be submitted by transferring it to a VoteBooth contract
    */
    access(all) resource Ballot: NonFungibleToken.NFT, Burner.Burnable {
        // The main token id, issued by Flow's internal uuid function
        access(all) let id: UInt64

        // The main option to represent the choice. A '0' indicates none selected yet
        access(self) var option: UInt8

        /*
            I'm going to use this flag to allow ballots to be revoked without having to actually check what the option in the Ballot really is (I'm trying to avoid this one as much as possible.) The idea is that voters can submit Ballots with the default option set. If that is indeed the case, when the Ballot Box receives a Ballot with this flag unset (false) sends it, as well as any Ballots in storage under the owner that is submitting it, to the BurnBox. This essentially allows a voter that regrets his/her vote but does not wants to replace it for another one. It may be a rare situation, but nevertheless.
            In the frontend, revoking a cast Ballot amounts to submit another Ballot with the default option set.
        */
        access(self) var hasVoted: Bool

        /*
            TODO: To review in a later stage

            I'm using this variable for the few cases where I don't have this resource in storage but I still need to know who owns it. In these situations (after loading the token from storage for instance), the 'self.owner!.address' parameter returns 'nil' because, at that particular instance where the token is "dangling", i.e., not stored anywhere, there is no way to access the native storage and therefore 'self' is nil.
            Can this affect voter privacy? Hard to tell at this point, because if someone is able to accesses this field other than the owner, than everything else is also available, which means something very wrong happened and all voter privacy was lost.
        */
        access(all) let ballotOwner: Address

        /*
            I need the address of the VoteBoothST contract deployer to be able to process this Ballot properly in the event of its, or a VoteBox containing it, destruction. This is mainly to be able to retrieve a valid reference to the BurnBox to where this Ballot should be sent to if the VoteBox containing it is set to be destroyed
        */
        access(all) let voteBoothDeployer: Address

        access(all) view fun getViews(): [Type] {
            return []
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }
        
        /*
            This function defines a callBack function to be automatically called when the Burner.burn function is invoked. I think (it's not clear yet) this call back needs to be implemented in the resource that is to be burned. This call back simply emits the related event.
        */
        access(contract) fun burnCallback() {
            if (VoteBoothST.printLogs) {
                log(
                    "burnCallback called for Ballot with id"
                    .concat(self.id.toString())
                    .concat(" for owner ")
                    .concat(self.ballotOwner.toString())
                )
            }
            emit VoteBoothST.BallotBurned(_ballotId: self.id, _voterAddress: self.ballotOwner)
        }

        access(all) view fun saySomething(): String {
            return "Hello from the VoteBoothST.Ballot Resource!"
        }
        
        // This is just another mandatory function from the NonFungibleToken standard. Return the DummyCollection in this case
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create VoteBoothST.DummyCollection()
        }
        
        access(all) view fun getElectionName(): String {
            return VoteBoothST._name
        }
        access(all) view fun getElectionSymbol(): String {
            return VoteBoothST._symbol
        }
        access(all) view fun getElectionBallot(): String {
            return VoteBoothST._ballot
        }
        access(all) view fun getElectionLocation(): String {
            return VoteBoothST._location
        }
        access(all) view fun getElectionOptions(): [UInt8] {
            return VoteBoothST._options
        }

        // Simple function to return if this Ballot is to revoke a previous one (true) or is a normal valid vote (false)
        access(all) view fun isRevoked(): Bool {
            return !self.hasVoted
        }

        /*
            Because I have all my Ballot ownership structures neatly wrapped into a single and highly protected resource which can only be accessed by the contract owner, I need to trust that all the processes up to this point have validated that the current Ballot owner (this function runs from the Ballot resource), namely, if one and only one Ballot was minted to this account, that the contract owner has no ballots, etc.
        */
        access(all) fun vote(newOption: UInt8?) {
            pre {
                self.owner != nil: "Need a valid owner to vote. Use a an authorized reference to this Ballot to vote please."
                self.owner!.address == self.ballotOwner: "Only the Ballot owner is allowed to vote!"
                self.ballotOwner != self.voteBoothDeployer: "The Administrator(".concat(self.voteBoothDeployer.toString()).concat(") is not allowed to vote!")
                newOption != nil: "Nil option provided. Cannot continue."
                self.getElectionOptions().contains(newOption!) || newOption! == VoteBoothST.defaultBallotOption: "The option '".concat(newOption!.toString()).concat("' is not among the valid for this election!")
            }

            // All validations are OK. Proceed with the vote but only if the option passed is not nil. Otherwise it is a Ballot revoke, which in this case I don't need to do anything else
            if (newOption! != VoteBoothST.defaultBallotOption) {
                self.option = newOption!
                self.hasVoted = true
            }
        }

        // NOTE: This function is for TEST and DEBUG purposes only. I mean, is not that serious given that I'm also going to encrypt the option value at a later stage, and this knowledge does violates voter privacy, but no one is going to die for it in a policy oriented democratic scenario. But just in case, this needs to be deleted/protected with an BoothAdmin entitlement before moving to a PROD environment. Worst case scenario, someone can calculate the tally before the "official" reveal. Bah, who cares really?
        // TODO: Delete or protect this function with BoothAdmin entitlement before moving to PROD.
        access(account) fun getVote(): UInt8? {
            pre {
                self.owner != nil: "This function can only be invoked through a reference!"
                self.owner!.address == self.ballotOwner: "Only the owner can invoke this function"
            }

            return self.option
        }

        init(_ballotOwner: Address, _voteBoothDeployer: Address) {
            self.id = self.uuid
            self.option = VoteBoothST.defaultBallotOption
            self.ballotOwner = _ballotOwner
            self.voteBoothDeployer = _voteBoothDeployer
            self.hasVoted = false
        }
    }
// ----------------------------- BALLOT END --------------------------------------------------------

// ----------------------------- VOTE BOX BEGIN ----------------------------------------------------
    access(all) resource VoteBox: Burner.Burnable {
        /*
            I'm only allowing one Ballot at a time in this VoteBox resource. The easier way is to define it as a single variable, with access(self) for maximum protection. But unfortunately, Flow/Cadence does like at all to mess around with nested resources unless they are set in some sort of storing structure. I can do this with an array, but a dictionary is better because it has a bunch of really useful base function
        */
        access(self) var storedBallot: @{UInt64: VoteBoothST.Ballot}
        
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
                let storedBallotRef: &VoteBoothST.Ballot? = &self.storedBallot[self.storedBallotId!]

                return storedBallotRef!.voteBoothDeployer
            }
        }

        // A simple function to return the address of the account where this resource is currently stored. This only works if this function is executed through a reference.
        access(all) view fun getVoteBoxOwner(): Address {
            if (self.owner == nil) {
                panic(
                    "ERROR: This VoteBox is not stored in a valid account. Unable to determine the storage account owner!"
                )
            }
            else {
                return self.owner!.address
            }
        }

        // Function to deposit a Ballot into this VoteBox. Though this Collection (of sorts. Its not a standard one) can theoretically receive multiple Ballots, I'm sticking it to a single Ballot at all times through a clever use of pre and post conditions, as well as with an exhaustive (perhaps too much even) set of internal validations, both in this function and others related.
        access(all) fun depositBallot(ballot: @VoteBoothST.Ballot) {
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
            self.storedBallotId = ballot.id

            // Deposit the Ballot
            let randomResource: @AnyResource? <- self.storedBallot[ballot.id] <- ballot

            // This is a theoretically impossible scenario, but deal with it just in case.
            if (randomResource.getType() == Type<@VoteBoothST.Ballot>()) {
                panic(
                    "ERROR: There was a @VoteBoothST.Ballot already stored in a VoteBox for address "
                    .concat(self.owner!.address.toString())
                    .concat(". This cannot happen!")
                )
            }
            // The expectation is that, at all times, a type Never? is returned if the internal dictionary is empty. If that is not the case, emit the NonNilTokenReturned event, but proceed with the destruction of the randomResource
            else if (randomResource.getType() != Type<Never?>()) {
                emit VoteBoothST.NonNilTokenReturned(_tokenType: randomResource.getType())
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

        access(all) fun saySomething(): String {
            return "Hello from the inside of the VoteBoothST.VoteBox resource!"
        }

        // Set this function to be called whenever I destroy one of these VoteBoxes. IMPORTANT: For this to work, I need to use the Burner contract to destroy any VoteBoxes. If I simply use the 'destroy' function, this function is not called!
        access(contract) fun burnCallback() {
            // Prepare this to emit the VoteBoxDestroyed event, namely, check if there's any Ballot stored, and if it is, grab its Id first
            let ballotId: UInt64? = self.storedBallotId

            // If the ballotId is not nil, do this properly and burn the Ballot before finishing
            if (ballotId != nil) {
                let ballotToBurn: @VoteBoothST.Ballot <- self.storedBallot.remove(key: ballotId!)!

                // Even though this resource is about to be destroyed, I'm super prickly with everything. Just to be consistent with the awesome programmer that I am, set the internal storedBallotOwner and storedBallotId to nil. It's pointless, but that how I roll
                self.storedBallotId = nil
                self.storedBallotOwner = nil

                let voteBoothDeployer: Address = ballotToBurn.voteBoothDeployer

                /*
                    In order to properly destroy (burn) any Ballot still in storage, send it to the VoteBooth deployer's BurnBox instead. At this level, this resource is unable to access the OwnerControl resource (only this deployer can do that) to maintain contract data consistency, i.e., to remove the respective entries from the internal dictionaries and such. Sending this Ballot to the BurnBox, which I can get from this resource because the reference to it is publicly accessible, solves all these problems. As such, I've set the contract deployer address, as in the address associated with the ballotPrinterAdmin resource required to mint the Ballot in the first place, as a access(all) parameter in the Ballot resource. Do it
                */
                let burnBoxRef: &VoteBoothST.BurnBox = getAccount(voteBoothDeployer).capabilities.borrow<&VoteBoothST.BurnBox>(VoteBoothST.burnBoxPublicPath) ??
                panic(
                    "Unable to retrieve a valid &VoteBoothST.BurnBox at "
                    .concat(VoteBoothST.burnBoxPublicPath.toString())
                    .concat(" from account ")
                    .concat(voteBoothDeployer.toString())
                )

                // Send the Ballot to the BurnBox
                burnBoxRef.depositBallotToBurn(ballotToBurn: <- ballotToBurn)
            }

            // Emit the respective event. NOTE: any ballotId emitted with this event refers to a Ballot set to burn in a BurnBox and not a Ballot that was destroyed
            // Just a reminder: I'm using a ternary operator to define the number of Ballots in the box that was destroyed. It reads as: is ballotId a nil ? if true, no Ballots in storage, thus set a 0. If not, there was one Ballot in storage, thus set a 1 instead.
            emit VoteBoothST.VoteBoxDestroyed(_ballotsInBox: ballotId == nil ? 0 : 1, _ballotId: ballotId)
        }

        /*
            NOTE: This function is for TEST and DEBUG purposes only.
            This function returns the current option in a Ballot stored internally, or nil if there are none.
            I've set the protections to prevent people other than the owner in the Ballot resource itself. If someone else tries to fetch the current vote other than the Ballot owner (which is also the VoteBox owner by obvious reasons), it fails a pre condition and panics. If there are no Ballots yet in the VoteBox, a nil is returned instead.
            TODO: Delete or protect this function with a proper entitlement before moving this to PROD
        */
        access(all) fun getCurrentVote(): UInt8? {
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
            let storedBallotRef: &VoteBoothST.Ballot? = &self.storedBallot[self.storedBallotId!]

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
                    .concat(storedBallotRef!.ballotOwner.toString())
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
        access(VoteEnable) fun castVote(option: UInt8?) {
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
            let storedBallotRef: &VoteBoothST.Ballot? = &self.storedBallot[self.storedBallotId!]

            if (storedBallotRef == nil) {
                panic(
                    "ERROR: Unable to get a valid &VoteBoothST.Ballot with stored id "
                    .concat(self.storedBallotId!.toString())
                    .concat(" for VoteBox in account ")
                    .concat(self.owner!.address.toString())
                )
            }

            // All is OK so far. Do it.
            storedBallotRef!.vote(newOption: option!)            
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
            let ballotToSubmit: @VoteBoothST.Ballot <- self.storedBallot.remove(key: self.storedBallotId!) ??
            panic(
                "Unable to load a @VoteBoothST.Ballot for a VoteBox in account "
                .concat(self.owner!.address.toString())
            )

            // Use the voteBoothDeployer address to retrieve a reference to the BallotBox to where the Ballot is to be submitted
            let voteBoothDeployerAccount: Address = ballotToSubmit.voteBoothDeployer
            let ballotBoxRef: &VoteBoothST.BallotBox = getAccount(voteBoothDeployerAccount).capabilities.borrow<&VoteBoothST.BallotBox>(VoteBoothST.ballotBoxPublicPath) ??
            panic(
                "Unable to get a valid &VoteBoothST.BallotBox in "
                .concat(VoteBoothST.ballotBoxPublicPath.toString())
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

// Contract-level Collection creation function
access(all) fun createEmptyVoteBox(owner: Address): @VoteBoothST.VoteBox {
    // This one is simple
    return <- create VoteBoothST.VoteBox(ownerAddress: owner)
}

// ----------------------------- BALLOT BOX BEGIN --------------------------------------------------
/*
    The BallotBox resource is going to be similar to a collection but not quite. I need it to store the ballots under an address key rather than an UInt64 key to keep one and only one Ballot submitted per voter, i.e., per address. Also, this allows me to properly implement the multiple vote casting feature in a more easy and flexible manner
*/
access(all) resource BallotBox {
    access(self) var submittedBallots: @{Address: VoteBoothST.Ballot}

    /*
        This function is one of the most important ones in this resource. It receives a Ballot NFT and puts it in the internal dictionary for future processing.
        I'm allowing multiple vote casting in this system, which is made insanely easy by the way Flow deals with resources storing other resources.
        These NFTs are stored in an internal @{Address: VoteBoothST.Ballot} dictionary, which invalidates double voting in the simplest, easiest possible, just by using a dictionary's base properties. Seeing how others have to bend themselves backwards to implement similar features in centralised (one election server doing everything) systems, makes their approach laughably over complicated. I'm completely preventing double voting and enabling multiple vote casting just by using a semi-basic data structure, which is what dictionaries are in Flow.
        Anyway, because I want this to be as informed as possible, I need to be a bit picky when processing a new Ballot, but even that is super easy: Instead of loading whatever may be at the dictionary position for the ballot.ballotOwner parameter, I'm getting a reference to it first and test its type. If it is indeed a Ballot, I'm loading it as such and processing it properly (as a vote re-submission). Otherwise, it's just more of the same, i.e., standard Flow.Collection behaviour.
    */
    access(all) fun submitBallot(ballot: @VoteBoothST.Ballot) {
        // Grab a reference to the value currently at the position self.submittedBallots[ballot.ballotOwner]
        let randomResourceRef: &AnyResource? = &self.submittedBallots[ballot.ballotOwner]
        
        // And save the ballotId and ballotOwner to clear out the OwnerControl strut at the end of this function
        let newBallotId: UInt64 = ballot.id
        let newOwner: Address = ballot.ballotOwner

        // Test first if its a nil (which would be the most common case). Proceed with standard NonFungibleToken.Collection behaviour
        if (randomResourceRef == nil) {
            // Is this a Ballot revoke?
            if (ballot.isRevoked()) {
                // Nothing much to do but to burn the received Ballot to revoke
                Burner.burn(<- ballot)

                // Decrement the total number of ballots minted because of this last burn
                VoteBoothST.decrementTotalBallotsMinted(ballots: 1)

                // The Ballot revoked in this case is the one received in this function
                emit BallotRevoked(_ballotId: newBallotId, _voterAddress: newOwner)
            }
            else {
                // Otherwise proceed with the normal submission
                let randomResource: @AnyResource? <- self.submittedBallots[ballot.ballotOwner] <- ballot

                // The randomResource is a nil, but I need to destroy it anyways
                destroy randomResource

                // Emit the BallotSubmitted event to finish this
                emit VoteBoothST.BallotSubmitted(_ballotId: newBallotId, _voterAddress: newOwner)

                // Increase the number of Ballots submitted
                VoteBoothST.incrementTotalBallotsSubmitted(ballots: 1)
            }
        }
        // If the type got was not nil, test if there's an old Ballot there instead. If so, replace it but emit a BallotModified event to warn that a Ballot was re-submitted
        else if (randomResourceRef.getType() == Type<&VoteBoothST.Ballot?>()) {
            // The process of replacing a type specific resource is a bit tricky and verbose, but still far easier than in any centralised approach. First, I need to retrieve a proper @VoteBooth.Ballot to get its id and ballotOwner
            let oldBallot: @VoteBoothST.Ballot <- self.submittedBallots.remove(key: ballot.ballotOwner) as! @VoteBoothST.Ballot

            let oldBallotId: UInt64 = oldBallot.id
            let oldBallotOwner: Address = oldBallot.ballotOwner

            // Destroy the oldBallot and store the new one in its place. Do it using the Burner so that the proper callback gets invoked
            Burner.burn(<- oldBallot)


            // Anytime a Ballot gets burned, it's one less in the total counter of minted Ballots. Decrement this counter as well
            VoteBoothST.decrementTotalBallotsMinted(ballots: 1)

            // Check if this is a revoke Ballot
            if (ballot.isRevoked()) {
                // If so, just burn the received Ballot as well, emit the BallotRevoke event with the old ballot owner and ballotId and decrement the total Ballots minted.
                Burner.burn(<- ballot)

                emit BallotRevoked(_ballotId: oldBallotId, _voterAddress: oldBallotOwner)
                
                VoteBoothST.decrementTotalBallotsMinted(ballots: 1)

                // The number of Ballots submitted needs to be decremented because, in this case, I'm short on one of them
                VoteBoothST.decrementTotalBallotsSubmitted(ballots: 1)
            }
            else {
                let nilResource: @AnyResource? <- self.submittedBallots[newOwner] <- ballot

                // This nilResource is indeed a nil. But Cadence is super picky (like me!) and requires me to do all this again. But this time I can destroy this thing without any regrets because I'm 100% at this point that I have a nil there.
                destroy nilResource

                // Emit the relevant event to finish this. The BallotModified even has 3 arguments: the id of the old Ballot, the id of the new Ballot, and the voterAddress, which is the same for both for obvious reason
                emit VoteBoothST.BallotModified(_oldBallotId: oldBallotId, _newBallotId: newBallotId, _voterAddress: newOwner)

                // In this case, DO NOT increment the number of Ballots submitted because I'm simply replacing an already submitted Ballot.
            }
        }
        // The last possible case is that something else was there instead, which should not happen in any circumstance. Store he Ballot anyways but emit a NonNilTokenReturned event in the process.
        else {
            // Check if it is a revoke first. If that's the case, proceed as usual but burn the new Ballot instead
            if (ballot.isRevoked()) {
                let nonNilResource: @AnyResource <- self.submittedBallots.remove(key: ballot.ballotOwner)

                emit VoteBoothST.NonNilTokenReturned(_tokenType: nonNilResource.getType())

                destroy nonNilResource

                Burner.burn(<- ballot)

                emit VoteBoothST.BallotRevoked(_ballotId: nil, _voterAddress: newOwner)

                // Finally, decrement the totalBallotsMinted to account with the new Ballot burn
                VoteBoothST.decrementTotalBallotsMinted(ballots: 1)
            }
            else {
                // Replace the Ballot by whatever non-nil resource was in that Ballot owner slot
                let nonNilResource: @AnyResource <- self.submittedBallots[ballot.ballotOwner] <- ballot
                
                // Emit the event and destroy the non nil resource
                emit VoteBoothST.NonNilTokenReturned(_tokenType: nonNilResource.getType())

                // But the ballot was successfully submitted anyway, so emit the proper event also
                emit VoteBoothST.BallotSubmitted(_ballotId: newBallotId, _voterAddress: newOwner)

                // And increment the totalBallotsSubmitted
                VoteBoothST.incrementTotalBallotsSubmitted(ballots: 1)

                destroy nonNilResource
            }
        }

        /*
            Irregardless if it is a ballot revoke or a normal submission, once a Ballot gets into this BallotBox, it's gone "forever", i.e., it cannot get back to a VoteBox or anything of the sort. As such, any new ballots that get into this function are going to be removed from OwnerControl structures
        */
        let ownerControlRef: &VoteBoothST.OwnerControl = self.owner!.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
        panic(
            "Unable to get a valid &VoteBoothST.OwnerControl at "
            .concat(VoteBoothST.ownerControlPublicPath.toString())
            .concat(" from account ")
            .concat(self.owner!.address.toString())
        )

        // Validate that the data currently stored in the OwnerControl is still consistent
        let ownerControlBallotId: UInt64? = ownerControlRef.getBallotId(owner: newOwner)
        let ownerControlOwner: Address? = ownerControlRef.getOwner(ballotId: newBallotId)

        if (ownerControlBallotId == nil) {
            // Emit the ContractDataInconsistent event and panic
            emit VoteBoothST.ContractDataInconsistent(_ballotId: ownerControlBallotId, _owner: newOwner)
            panic(
                "ERROR: Unable to find a valid BallotId in the OwnerControl for owner "
                .concat(newOwner.toString())
            )
        }
        else if (ownerControlOwner == nil) {
            emit VoteBoothST.ContractDataInconsistent(_ballotId: newBallotId, _owner: ownerControlOwner)
            panic(
                "ERROR: Unable to find a valid BallotOwner in the Owner control for ballotId "
                .concat(newBallotId.toString())
            )
        }
        else if (ownerControlBallotId! != newBallotId) {
            emit VoteBoothST.ContractDataInconsistent(_ballotId: ownerControlBallotId!, _owner: newOwner)
            panic(
                "ERROR: Mismatch between the ballotId provided ("
                .concat(newBallotId.toString())
                .concat(") and the ballotId retrieved from the OwnerControl (")
                .concat(ownerControlBallotId!.toString())
                .concat(") for owner ")
                .concat(newOwner.toString())
            )
        }
        else if (ownerControlOwner! != newOwner) {
            emit VoteBoothST.ContractDataInconsistent(_ballotId: newBallotId, _owner: ownerControlOwner)
            panic(
                "ERROR: Mismatch between the owner provided ("
                .concat(newOwner.toString())
                .concat(") and the owner retrieved from the OwnerControl (")
                .concat(ownerControlOwner!.toString())
                .concat(") for ballotId ")
                .concat(newBallotId.toString())
            )
        }

        // If this gets to this point, all data is still consistent. Remove the entries from the OwnerControl
        ownerControlRef.removeBallotId(ballotId: newBallotId, owner: newOwner)
        ownerControlRef.removeOwner(owner: newOwner, ballotId: newBallotId)
    }

    /*
        This function is quite important but also very simple. It should only be invoked by the Tally contract
    */
    // TODO: Create a 'TallyAdmin' entitlement in the Tally contract (at some point) and replace the current 'BoothAdmin' entitlement with it. This means that not even this contract deployer can withdraw Ballots willy nilly. Only the Tally contract should be able to withdraw Ballots from this resource. This is kinda tricky to do, but I think it should be possible to do.
    access(TallyAdmin) fun withdrawBallot(ballotOwner: Address): @VoteBoothST.Ballot {
        // Standard NonFungibleToken.Collection.withdraw behaviour. I don't need any more fancy bells and whistles with this one, really.
        let vote: @VoteBoothST.Ballot <- self.submittedBallots.remove(key: ballotOwner) ??
        panic(
            "Unable to retrieve a vote from owner "
            .concat(ballotOwner.toString())
        )

        // Just to make sure everything checks out, decrease the totalBallotsSubmitted since this should reflect the same number of Ballots stored in a BallotBox at all times
        VoteBoothST.decrementTotalBallotsSubmitted(ballots: 1)

        return <- vote
    }

    // Simple function just to check how many Ballots were submitted thus far
    access(all) view fun getSubmittedBallotCount(): Int {
        return self.submittedBallots.length
    }

    // Another simple function that simply returns if a Ballot for a given address is already in storage (was submitted) or not. This function is BoothAdmin protected to preserve voter privacy as much as possible. I don't anyone other than the contract deployer to be able to determine if a given voter has vote already or not.
    access(BoothAdmin) view fun getIfOwnerVoted(ballotOwner: Address): Bool {
        // Grab a reference to a potential Ballot in the position 'ballotOwner' and test if it is a nil or not. Return false or true accordingly
        let resourceRef: &AnyResource? = &self.submittedBallots[ballotOwner]

        if (resourceRef.getType() == Type<Never?>() || resourceRef.getType() != Type<&VoteBoothST.Ballot?>()) {
            // If the resource is a nil (which corresponds to type Never?) or some other type than the VoteBoothST.Ballot, return a false. There's no valid Ballot submitted under this address
            return false
        }

        // If the above condition is not triggered, the resource is of the correct type, so return a true instead
        return true
    }

    access(all) view fun saySomething(): String {
        return "Hello from inside the VoteBoothST.BallotBox resource!"
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
    access(self) var ballotsToBurn: @{UInt64: VoteBoothST.Ballot}

    // This function receives a ballotId as argument, checks if there's a valid entry in the ballotsToBurn dictionary. If so, returns true because the ballot in question is mark for burn. If not, returns a false. This may mean that either no Ballot with that id was received, or the Ballot was burn already
    access(all) fun isBallotToBeBurned(ballotId: UInt64): Bool {
        if (self.ballotsToBurn[ballotId] == nil) {
            return false
        }

        return true
    }

    access(all) fun depositBallotToBurn(ballotToBurn: @VoteBoothST.Ballot) {
        // As usual, "clean up" the dictionary entry, while checking if whatever was in the dictionary position IS NOT a valid @VoteBoothST.Ballot
        let ballotToBurnId: UInt64 = ballotToBurn.id
        let ballotToBurnOwner: Address = ballotToBurn.ballotOwner

        // Set the ballot in the dictionary
        let randomResource: @AnyResource? <- self.ballotsToBurn[ballotToBurn.id] <- ballotToBurn

        let randomResourceType: Type = randomResource.getType()

        // This is the worst case: I'm trying to replace an already existing Ballot in this dictionary. Panic in this case to prevent unwanted burns
        if (randomResource != nil && randomResourceType == Type<@VoteBoothST.Ballot>()) {
            panic(
                "ERROR: Found a valid @VoteBoothST.Ballot already stored with key "
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

        emit VoteBoothST.BallotSetToBurn(_ballotId: ballotToBurnId, _voterAddress: ballotToBurnOwner)
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
        let ownerControlRef: &VoteBoothST.OwnerControl = self.owner!.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
        panic(
            "Unable to get a valid &VoteBoothSt.OwnerControl at "
            .concat(VoteBoothST.ownerControlPublicPath.toString())
            .concat(" for account ")
            .concat(self.owner!.address.toString())
        )

        for ballotId in ballotIdsToBurn {
            // Grab a Ballot to process
            let ballotToBurn: @VoteBoothST.Ballot <- self.ballotsToBurn.remove(key: ballotId) ??
            panic(
                "Unable to recover a @VoteBoothST.Ballot from BurnBox.ballotsToBurn for id "
                .concat(ballotId.toString())
                .concat(". The dictionary returned a nil!")
            )

            // The Ballot set to burn should have valid entries in the OwnerControl resource. Check it
            let storedBallotId: UInt64? = ownerControlRef.getBallotId(owner: ballotToBurn.ballotOwner)

            if (storedBallotId == nil) {
                // Data inconsistency detected! There is no ballotId associated to the owner in the ballot to burn in the OwnerControl.owners dictionary. Emit the ContractDataInconsistent but don't panic yet. This is recoverable. Ensure the other dictionary is consistent, burn the Ballot and move on
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId, _owner: ballotToBurn.ballotOwner)

                // This Ballot should not exist. In this case, check the ballotIds dictionary and correct it before burning the Ballot
                let storedBallotOwner: Address? = ownerControlRef.getOwner(ballotId: ballotToBurn.id)

                if (storedBallotOwner != nil) {
                    // Looks like there's an entry in ballotIds dictionary for this ballot. Solve the inconsistency and move on
                    ownerControlRef.removeBallotId(ballotId: ballotToBurn.id, owner: storedBallotOwner!)
                }
            }
            else if (storedBallotId! != ballotToBurn.id) {
                // In this case, the owner of the ballot to burn has a different ballotId associated to it, which means that, theoretically, the owner has two ballots... somehow. In this case, emit two events with the two ballotIds and the same address and then panic... This situation is critical and needs to be taken care before moving on. Ideally this branch should nevern be called
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId!, _owner: ballotToBurn.ballotOwner)

                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotToBurn.id, _owner: ballotToBurn.ballotOwner)

                panic(
                    "ERROR: Major data inconsistency found: Address "
                    .concat(ballotToBurn.ballotOwner.toString())
                    .concat(" has two Ballots associated to it: the ballot to burn has id ")
                    .concat(ballotToBurn.id.toString())
                    .concat(" but the OwnerControl.owners has this address associated to ballotId ")
                    .concat(storedBallotId!.toString())
                    .concat(". Cannot continue until this inconsistency is solved!")
                )
            }

            // All data is still consistent. Remove the related entries from both ballotIds and owners dictionaries from the OwnerControl resource and finally burn the damn Ballot. Ish...
            ownerControlRef.removeBallotId(ballotId: ballotToBurn.id, owner: ballotToBurn.ballotOwner)

            ownerControlRef.removeOwner(owner: ballotToBurn.ballotOwner, ballotId: ballotToBurn.id)

            // Destroy (burn) the Ballot. This should emit a BallotBurned event
            Burner.burn(<- ballotToBurn)

            // Once a Ballot is destroyed, I also need to decrease the totalBallotsMinted by 1
            VoteBoothST.decrementTotalBallotsMinted(ballots: 1)

            // Done. This is the end of the for loop cycle. This should repeat for all ballots set in storage to be burned.
        }
    }

    // The usual saySomething function just to check if this thing is minimally working. I have one of these in each resource of this contract
    access(all) fun saySomething(): String {
        return "Hello from inside the BurnBox resource!"
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
    Authorized references are indicated with a 'auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin' and these can only be successfully obtained from the
    'account.storage.borrow<auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin>(PATH)', instead of the usual 'account.capabilities.borrow...'
    Because I now need to access the 'storage' subset of the Flow API, I necessarily need to obtain this reference from the transaction signer and no one else! The transaction need to be signed by the deployed to work! Cool, that's exactly what I want!
    It is now impossible to call the 'printBallot' function from a reference obtained by the usual, capability-based reference retrievable by a simple account reference, namely, from 'let account: &Account = getAccount(accountAddress)'

    NOTE: VERY IMPORTANT
    This resource can only be used as a reference, never directly as a resource!!
    In other words, never load this, use it, and then put it back into storage. Because, not only it is extremely inefficient from the blockchain point of view, but most importantly, the resource is dangling and, as such, the self.owner!.address is going to break this due to the fact that self.owner == nil! This resource relies A LOT in knowing who the owner of the resource is (mostly because of the OwnerControl resource), so one more reason to avoid this.
*/
    access(all) resource BallotPrinterAdmin {
        // Use this parameter to store the contract owner, given that this resource is only (can only) be created in the contract constructor, and use it to prevent the contract owner from voting. It's a simple but probably necessary precaution.

        access(BoothAdmin) fun printBallot(voterAddress: Address): @VoteBoothST.Ballot {
            pre {
                // First, ensure that the contract owner (obtainable via self.owner!.address) does not match the address provided.
                self.owner!.address != voterAddress: "The contract owner is not allowed to vote!"
            }

            let newBallot: @Ballot <- create Ballot(_ballotOwner: voterAddress, _voteBoothDeployer: self.owner!.address)

            // Load a reference to the ownerControl resource from public storage
            let ownerControlRef: &VoteBoothST.OwnerControl = self.owner!.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
            panic(
                "Unable to get a valid &VoteBoothST.OwnerControl at "
                .concat(VoteBoothST.ownerControlPublicPath.toString())
                .concat(" for account ")
                .concat(self.owner!.address.toString())
            )

            // Validate that the current owner does not has a Ballot already, i.e., if the resource internal dictionaries are consistent
            // First, check if the address provided has no Ballot associated to it
            let ballotId: UInt64? = ownerControlRef.getBallotId(owner: voterAddress)

            if (ballotId != nil) {
                // Data inconsistency detected. Emit the respective event and panic
                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotId, _owner: voterAddress)

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
                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotId!, _owner: voterAddress)
                
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
            VoteBoothST.incrementTotalBallotsMinted(ballots: 1)

            return <- newBallot
        }

        access(all) view fun saySomething(): String {
            return "Hello from inside the VoteBoothST.BallotPrinterAdmin Resource"
        }

        /*
            This function receives the identification number of a token that was minted by the BoothAdmin Ballot printer and removes all entries from the internal dictionaries. This is useful for when a token is burned, so that the internal contract data structure maintains its consistency.
            For obvious reasons, this function is also BoothAdmin entitlement protected. Also, I've decided to mix the burnBallot function with this one to minimize the probability of creating inconsistencies in these structures
        */
        access(BoothAdmin) fun burnBallot(ballotToBurn: @VoteBoothST.Ballot): Void {
            // Get an authorized reference to the OwnerControl resource with a Remove modifier
            let ownerAccount: &Account = getAccount(self.owner!.address)

            let ownerControlRef: &VoteBoothST.OwnerControl = ownerAccount.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
            panic(
                "Unable to get a valid &VoteBoothST.OwnerControl at "
                .concat(VoteBoothST.ownerControlPublicPath.toString())
                .concat(" for account ")
                .concat(self.owner!.address.toString())
            )

            // Validate that the Ballot provided is correctly inserted into the OwnerControl structures. Panic if any inconsistencies are detected
            let storedBallotId: UInt64? = ownerControlRef.getBallotId(owner: ballotToBurn.ballotOwner)

            if (storedBallotId == nil) {
                // Data inconsistency detected! There is no ballotId associated to the owner in the ballot to burn in the 'owners' dictionary. Emit the event but don't panic: make sure both dictionaries are consistent, burn the token and get out
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId, _owner: ballotToBurn.ballotOwner)

                // This ballot should not exist. In this case, check the other internal dictionary and correct it and burn the ballot before panicking
                let storedBallotOwner: Address? = ownerControlRef.getOwner(ballotId: ballotToBurn.id)

                if (storedBallotOwner != nil) {
                    // It appears that there's a record for this ballot in the owners dictionary. Clean it to keep data consistency
                    ownerControlRef.removeBallotId(ballotId: ballotToBurn.id, owner: storedBallotOwner!)
                }
            }
            else if (storedBallotId! != ballotToBurn.id) {
                // The owner of the ballot to burn has a different ballotId associated to it, which means that, theoretically, the owner has two ballots... somehow. In this case, emit two events with the two ballotIds and the same address and then panic... This situation is critical and needs to be taken care before moving on. Ideally this branch should never be called
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId!, _owner: ballotToBurn.ballotOwner)

                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotToBurn.id, _owner: ballotToBurn.ballotOwner)

                panic(
                    "ERROR: Major data inconsistency found: Address "
                    .concat(ballotToBurn.ballotOwner.toString())
                    .concat(" has two Ballots associated to it: the ballot to burn has id ")
                    .concat(ballotToBurn.id.toString())
                    .concat(" but the OwnerControl.owners has this address associated to ballotId ")
                    .concat(storedBallotId!.toString())
                    .concat(". Cannot continue until this inconsistency is solved!")
                )

            }
            else {
                // All is consistent, it seems. Remove related entries from both OwnerControl internal dictionaries. The last step of this function is to burn the ballot provided
                ownerControlRef.removeBallotId(ballotId: ballotToBurn.id, owner: ballotToBurn.ballotOwner)

                ownerControlRef.removeOwner(owner: ballotToBurn.ballotOwner, ballotId: ballotToBurn.id)

            }

            // Destroy (burn) the Ballot finally
            Burner.burn(<- ballotToBurn)

            // Decrease the totalBallotsMinted by 1 to account for this burned Ballots
            VoteBoothST.decrementTotalBallotsMinted(ballots: 1)
        }

        init() {
        }
    }
// ----------------------------- BALLOT PRINTER END ------------------------------------------------

// ----------------------------- OWNER CONTROL BEGIN -------------------------------------------------
    /* 
        This resource is used to keep track of the ownership of ballots. This turns out to be the simplest approach. This resource is created and immediately stored and capability reference published, as usual. I need to keep this resource as open (with access(all)) as possible because I want to operate on it from other contract functions themselves
    */
    access(all) resource OwnerControl {
        access(self) var ballotIds: {UInt64: Address}
        access(self) var owners: {Address: UInt64}

        // Retrieve the ballotIds dictionary
        access(BoothAdmin) fun getBallotIds(): {UInt64: Address} {
            return self.ballotIds
        }

        // And this one returns just the size of the ballotIds, i.e., it calculates how many owners exists for the ballots
        access(all) fun getBallotIdsCount(): Int {
            return self.ballotIds.length
        }

        // Retrieve the owners dictionary
        access(BoothAdmin) fun getOwners(): {Address: UInt64} {
            return self.owners
        }

        // And this one returns the number of ballots associated to owners in the system, i.e., the number of ballots minted/active so far
        access(all) fun getOwnersCount(): Int {
            return self.owners.length
        }

        // Get the owner address for a given ballotId
        access(all) fun getOwner(ballotId: UInt64): Address? {
            return self.ballotIds[ballotId]
        }

        // Get the ballotId for the given owner
        access(all) fun getBallotId(owner: Address): UInt64? {
            return self.owners[owner]
        }

        // Set function to create a new entry in the ballotIds dictionary
        access(account) fun setBallotId(ballotId: UInt64, owner: Address) {
            /* 
                Check first that there are no ContractDataInconsistencies around. If there are, emit the ContractDataInconsistent event, but carry on. Replace the existing parameters.
                There's a chance that this might be the wrong approach, that I should just panic this and wait for it to be fixed. I need to keep an eye on this thing any way...
            */

            let storedOwner: Address? = self.ballotIds[ballotId]

            if (storedOwner != nil) {
                // The ideal scenario is that I get a nil from this one, meaning that no owner is still registered under this ballotId. If this is not the case, emit the ContractDataInconsistent event with the address returned from the last step, but carry on with the rest of the process, i.e., replace the old owner for the one provided
                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotId, _owner: storedOwner!)
            }
            
            self.ballotIds[ballotId] = owner
        }

        // Set function to create a new entry in the owners dictionary
        access(account) fun setOwner(owner: Address, ballotId: UInt64) {
            // Same process as before for this one as well

            let storedBallotId: UInt64? = self.owners[owner]

            if (storedBallotId != nil) {
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId!, _owner: owner)
            }
            self.owners[owner] = ballotId
        }

        // Remove function to delete the entry from the ballotIds dictionary for the ballotId key provided
        access(account) fun removeBallotId(ballotId: UInt64, owner: Address) {
            let storedOwner: Address? = self.ballotIds.remove(key: ballotId)

            // Check if the ballotOwner returned matches the one provided in the arguments. Emit the ContractDataInconsistency event
            if (storedOwner == nil || storedOwner! != owner) {
                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotId, _owner: storedOwner)
            }
        }

        // Remove function to delete the entry from the owners dictionary for the owner key provided
        access(account) fun removeOwner(owner: Address, ballotId: UInt64) {
            let storedBallotId: UInt64? = self.owners.remove(key: owner)

            // Same as before, check for data inconsistencies and emit the usual event if that's the case
            if (storedBallotId == nil || storedBallotId! != ballotId) {
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId, _owner: owner)
            }
        }

        // This function validates if this structure is still consistent or not. If all works well, the owners and ballotIds dictionaries should ALWAYS have the same number of entries
        // given that they are always modified at the same time.
        access(all) fun isConsistent(): Bool {
            return (self.ballotIds.length == self.owners.length)
        }

        // Resource constructor. It simply sets the internal dictionaries to empty ones
        init() {
            self.ballotIds = {}
            self.owners = {}
        }
    }
// ----------------------------- OWNER CONTROL END ---------------------------------------------------

// ----------------------------- CONTRACT LOGIC BEGIN ----------------------------------------------
    // Dummy Collection just to have this contract to conform to the NonFungibleToken standard
    access(all) resource DummyCollection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            // Check if a @VoteBoothST.Ballot is being deposited and panic if that's the case. I don't want these NFTs to be able to be deposited in this DummyCollection
            // Try to force cast this token to a @VoteBoothST.Ballot. If successful, panic because I don't want this token to be deposited. Otherwise, force-casting a non-Ballot to a Ballot resource is going to panic by itself. Either way, this function becomes unusable, which is exactly what I want
            let dummyBallot: @VoteBoothST.Ballot <- token as! @VoteBoothST.Ballot

            // Destroy this token in any case. I just need to create a function with this name but I don't actually need to deposit it into the internal dictionary.
            destroy dummyBallot
        }

        access(all) view fun getLength(): Int {
            return self.ownedNFTs.length
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            // Return an empty dictionary in this case. This is just a dummy function
            return {}
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            // This one always returns true. All types are supported. This is irrelevant because I'm doing my own Collections.
            return true
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            // Don't even bother with this one. It returns an option, so return nil and get on with it
            return nil
        }

        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            // For this case, create a dummy, empty NFT and return it
            let dummyNFT: @{NonFungibleToken.NFT}? <- self.ownedNFTs.remove(key: withdrawID)

            // This is going to break this function because the dummyNFT is going to be a nil 100% of the time. I don't care really
            return <- dummyNFT!
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create DummyCollection()
        }

        init() {
            self.ownedNFTs <- {}
        }
    }

    // Just a bunch of getters for the main internal parameters
    access(all) view fun getElectionName(): String {
        return self._name
    }
    access(all) view fun getElectionSymbol(): String {
        return self._symbol
    }
    access(all) view fun getElectionLocation(): String {
        return self._location
    }
    access(all) view fun getElectionBallot(): String {
        return self._ballot
    }
    access(all) view fun getElectionOptions(): [UInt8] {
        return self._options
    }

    // This is another mandatory NonFungibleToken standard function. Return the DummyCollection
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create DummyCollection()
    }

    access(all) view fun saySomething(): String {
        return "Hello from the VoteBoothST.cdc contract level!"
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return []
    }
    
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        return nil
    }

    // Add a couple of burners for the collections as well
    access(all) fun burnVoteBox(voteBoxToBurn: @VoteBoothST.VoteBox) {
        Burner.burn(<- voteBoxToBurn)
    }

    // Very simple function to determine the address of the account that deployed this contract in the first place
    access(all) view fun getContractDeployer(): Address {
        return self.account.address
    }

    // The next couple of functions are simple wrappers to allow emitting events from within a transaction
    access(all) view fun emitVoteBoxCreated(voterAddress: Address) {
        emit VoteBoothST.VoteBoxCreated(_voterAddress: voterAddress)
    }

    access(all) view fun emitBallotNotDelivered(voterAddress: Address, reason: Int) {
        emit VoteBoothST.BallotNotDelivered(_voterAddress: voterAddress, _reason: reason)
    }

    /*
        The next six functions are getters and setters (2 to increase the totals, and another 2 for decrease them) for the totalBallotsMinted and totalBallotsSubmitted. The setters are set as access(account) so that they can only be invoked from other resources in the deployer account (such as the ballotPrinterAdmin) while the variables have access(self) so that they can only be manipulated by these functions. The getters have access(all) because they are read-only, so the risk is pretty much non-existent.
    */
    access(all) view fun getTotalBallotsMinted(): UInt64 {
        return self.totalBallotsMinted
    }

    access(all) view fun getTotalBallotsSubmitted(): UInt64 {
        return self.totalBallotsSubmitted
    }

    access(account) fun incrementTotalBallotsMinted(ballots: UInt64): Void {        
        self.totalBallotsMinted = self.totalBallotsMinted + ballots
    }

    access(account) fun incrementTotalBallotsSubmitted(ballots: UInt64): Void {
        self.totalBallotsSubmitted = self.totalBallotsSubmitted + ballots
    }

    access(account) fun decrementTotalBallotsMinted(ballots: UInt64): Void {
        // Validate first that this decrement does not bring the total < 0 (which is not event possible because I've set this variable as a UInt64, the 'U' in it being unsigned)
        if (ballots > self.totalBallotsMinted) {
            panic(
                "Unable to decrease the total Ballots minted! Cannot decrease a total of "
                .concat(self.totalBallotsMinted.toString())
                .concat(" minted ballots by ")
                .concat(ballots.toString())
            )
        }

        // The subtraction is possible (result >= 0). Carry on
        self.totalBallotsMinted = self.totalBallotsMinted - ballots
    }

    access(account) fun decrementTotalBallotsSubmitted(ballots: UInt64): Void {
        if (ballots > self.totalBallotsSubmitted) {
            panic(
                "Unable to decrease the total Ballots submitted! Cannot decrease the total of "
                .concat(self.totalBallotsSubmitted.toString())
                .concat(" submitted ballots by ")
                .concat(ballots.toString())
            )
        }

        self.totalBallotsSubmitted = self.totalBallotsSubmitted - ballots
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

    TODO: Fix the contract to get an array of options as the electionOptions!
*/
    init(name: String, symbol: String, ballot: String, location: String, electionOptions: [UInt8], printLogs: Bool) {
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

        self._name = name
        self._symbol = symbol
        self._ballot = ballot
        self._location = location


        self._options = electionOptions

        self.defaultBallotOption = 0

        // I want to use the default option (0) to signal Ballots to be revoked. It's a bit of a pointless feature, but important nonetheless. As such, I need to make sure that 0 is not among the election options provided
        if (electionOptions.contains(self.defaultBallotOption)) {
            panic(
                "ERROR: The default Ballot option ("
                .concat(self.defaultBallotOption.toString())
                .concat(") is among the election options provided! Please remove this option from the valid ones to continue!")
            )
        }

        self.totalBallotsMinted = 0
        self.totalBallotsSubmitted = 0

        self.printLogs = printLogs

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

        let randomResource03: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.ownerControlStoragePath)

        if (randomResource03 != nil) {
            log(
                "Found a type '"
                .concat(randomResource03.getType().identifier)
                .concat("' object in at ")
                .concat(self.ownerControlStoragePath.toString())
                .concat(" path in account ")
                .concat(self.account.address.toString())
                .concat(" storage!")
            )
        }

        destroy randomResource03

        let oldCap03: Capability? = self.account.capabilities.unpublish(self.ownerControlPublicPath)

        if (oldCap03 != nil) {
            log(
                "Found an active capability at "
                .concat(self.ownerControlPublicPath.toString())
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

        // Process the ownerControl resource
        self.account.storage.save(<- create VoteBoothST.OwnerControl(), to: self.ownerControlStoragePath)

        let ownerControlCapability: Capability<&VoteBoothST.OwnerControl> = self.account.capabilities.storage.issue<&VoteBoothST.OwnerControl> (self.ownerControlStoragePath)

        self.account.capabilities.publish(ownerControlCapability, at: self.ownerControlPublicPath)

        // Process the BallotPrinterAdmin resource
        self.account.storage.save(<- create BallotPrinterAdmin(), to: self.ballotPrinterAdminStoragePath)

        let printerCapability: Capability<&VoteBoothST.BallotPrinterAdmin> = self.account.capabilities.storage.issue<&VoteBoothST.BallotPrinterAdmin> (self.ballotPrinterAdminStoragePath)

        self.account.capabilities.publish(printerCapability, at: self.ballotPrinterAdminPublicPath)

        // Repeat the process for the BallotBox
        self.account.storage.save(<- create BallotBox(), to: self.ballotBoxStoragePath)

        let BallotBoxCap: Capability<&VoteBoothST.BallotBox> = self.account.capabilities.storage.issue<&VoteBoothST.BallotBox>(self.ballotBoxStoragePath)

        self.account.capabilities.publish(BallotBoxCap, at: self.ballotBoxPublicPath)

        // Process the BurnBox as well
        self.account.storage.save(<- create BurnBox(), to: self.burnBoxStoragePath)

        let BurnBoxCap: Capability<&VoteBoothST.BurnBox> = self.account.capabilities.storage.issue<&VoteBoothST.BurnBox> (self.burnBoxStoragePath)
        self.account.capabilities.publish(BurnBoxCap, at: self.burnBoxPublicPath)

        emit VoteBoothST.BallotBoxCreated(_accountAddress: self.account.address)
    }
}
// ----------------------------- CONSTRUCTOR END ---------------------------------------------------
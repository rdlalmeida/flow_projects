/*
    This contract is just a cleaner, more efficient (and hopefully functional) version of the VoteBooth contract. As usual, I've wrote 98% of the last attempt at this contract in one sitting, hoping that by taking care of all the issues revealed by VS code would be enough. After wasting weeks writing a smart contract with almost 1000 lines (a lot of those are these very long comments I'm so prone to write), I found out that my stupid v.12 contract does everything... except storing Ballots in VoteBoxes!!! Which is, like, one of the most import steps of this process!

    I did try to debug this thing for a while, but it is just too much... My best approach is to re-write this thing from scratch and test it thoroughly as much as possible, just to make sure that this contract continues working as supposed.

    TODO: Complete the ballotOwners and owners mechanics
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
    access(all) event BallotModified(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotBurned(_ballotId: UInt64, _voterAddress: Address)
    access(all) event ContractDataInconsistent(_ballotId: UInt64?, _ballotOwner: Address?)
    access(all) event VoteBoxCreated(_voterAddress: Address)
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
        4 - The VoteBox is empty but the 'ballotOwners' dictionary has an entry for the current Ballot id
    */
    access(all) event BallotNotDelivered(_voterAddress: Address, _reason: Int)

    // CUSTOM ENTITLEMENTS
    access(all) entitlement Admin

    // CUSTOM VARIABLES
    access(all) let _name: String
    access(all) let _symbol: String
    access(all) let _ballot: String
    access(all) let _location: String
    access(all) let _options: [UInt64]

    // I'm using these to do an internal tracking mechanism to protect this against double voting and the like
    access(all) var totalBallotsMinted: UInt64
    access(all) var totalBallotsSubmitted: UInt64

// ----------------------------- OWNER CONTROL BEGIN -------------------------------------------------
    /* 
        This resource is used to keep track of the ownership of ballots. This turns out to be the simplest approach. This resource is created and immediately stored and capability reference published, as usual. I need to keep this resource as open (with access(all)) as possible because I want to operate on it from other contract functions themselves
    */
    access(all) resource OwnerControl {
        access(self) var ballotOwners: {UInt64: Address}
        access(self) var owners: {Address: UInt64}

        // Retrieve the ballotOwners dictionary
        access(Admin) fun getBallotOwners(): {UInt64: Address} {
            return self.ballotOwners
        }

        // And this one returns just the size of the ballotOwners, i.e., it calculates how many owners exists for the ballots
        access(all) fun getOwnersCount(): Int {
            return self.ballotOwners.length
        }

        // Retrieve the owners dictionary
        access(Admin) fun getOwners(): {Address: UInt64} {
            return self.owners
        }

        // And this one returns the number of ballots associated to owners in the system, i.e., the number of ballots minted/active so far
        access(all) fun getBallotCount(): Int {
            return self.owners.length
        }

        // Get the owner address for a given ballotId
        access(all) fun getBallotOwner(ballotId: UInt64): Address? {
            return self.ballotOwners[ballotId]
        }

        // Get the ballotId for the given owner
        access(all) fun getBallotId(owner: Address): UInt64? {
            return self.owners[owner]
        }

        // Set function to create a new entry in the ballotOwners dictionary
        access(account) fun setBallotOwner(ballotId: UInt64, ballotOwner: Address) {
            /* 
                Check first that there are no ContractDataInconsistencies around. If there are, emit the ContractDataInconsistent event, but carry on. Replace the existing parameters.
                There's a chance that this might be the wrong approach, that I should just panic this and wait for it to be fixed. I need to keep an eye on this thing any way...
            */

            let storedBallotOwner: Address? = self.ballotOwners[ballotId]

            if (storedBallotOwner != nil) {
                // The ideal scenario is that I get a nil from this one, meaning that no owner is still registered under this ballotId. If this is not the case, emit the ContractDataInconsistent event with the address returned from the last step, but carry on with the rest of the process, i.e., replace the old owner for the one provided
                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotId, _ballotOwner: storedBallotOwner!)
            }
            
            self.ballotOwners[ballotId] = ballotOwner
        }

        // Set function to create a new entry in the owners dictionary
        access(account) fun setOwner(ballotOwner: Address, ballotId: UInt64) {
            // Same process as before for this one as well

            let storedBallotId: UInt64? = self.owners[ballotOwner]

            if (storedBallotId != nil) {
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId!, _ballotOwner: ballotOwner)
            }
            self.owners[ballotOwner] = ballotId
        }

        // Remove function to delete the entry from the ballotOwners dictionary for the ballotId key provided
        access(account) fun removeBallotOwner(ballotId: UInt64, ballotOwner: Address) {
            let storedBallotOwner: Address? = self.ballotOwners.remove(key: ballotId)

            // Check if the ballotOwner returned matches the one provided in the arguments. Emit the ContractDataInconsistency event
            if (storedBallotOwner == nil || storedBallotOwner! != ballotOwner) {
                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotId, _ballotOwner: storedBallotOwner)
            }
        }

        // Remove function to delete the entry from the owners dictionary for the ballotOwner key provided
        access(account) fun removeOwner(ballotOwner: Address, ballotId: UInt64) {
            let storedBallotId: UInt64? = self.owners.remove(key: ballotOwner)

            // Same as before, check for data inconsistencies and emit the usual event if that's the case
            if (storedBallotId == nil || storedBallotId! != ballotId) {
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId, _ballotOwner: ballotOwner)
            }
        }

        // This function validates if this structure is still consistent or not. If all works well, the owners and ballotOwners dictionaries should ALWAYS have the same number of entries
        // given that they are always modified at the same time.
        access(all) fun isConsistent(): Bool {
            return (self.ballotOwners.length == self.owners.length)
        }

        // Resource constructor. It simply sets the internal dictionaries to empty ones
        init() {
            self.ballotOwners = {}
            self.owners = {}
        }
    }
// ----------------------------- OWNER CONTROL END ---------------------------------------------------

// ----------------------------- BALLOT BEGIN ------------------------------------------------------
    /*
        This is the main actor in this process. The Ballot NFT is issued on demand, is editable by the voter, and can be submitted by transferring it to a VoteBooth contract
    */
    access(all) resource Ballot: NonFungibleToken.NFT, Burner.Burnable {
        // The main token id, issued by Flow's internal uuid function
        access(all) let id: UInt64

        // The main option to represent the choice. A '0' indicates none selected yet
        access(self) var option: UInt64

        /*
            TODO: To review in a later stage

            I'm using this variable for the few cases where I don't have this resource in storage but I still need to know who owns it. In these situations (after loading the token from storage for instance), the 'self.owner!.address' parameter returns 'nil' because, at that particular instance where the token is "dangling", i.e., not stored anywhere, there is no way to access the native storage and therefore 'self' is nil.
            Can this affect voter privacy? Hard to tell at this point, because if someone is able to accesses this field other than the owner, than everything else is also available, which means something very wrong happened and all voter privacy was lost.
        */
        access(all) let ballotOwner: Address

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
            emit VoteBoothST.BallotBurned(_ballotId: self.id, _voterAddress: self.ballotOwner)
        }

        access(all) view fun saySomething(): String {
            return "Hello from the VoteBoothST.Ballot Resource!"
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            let voteBox: @VoteBoothST.VoteBox <- create VoteBoothST.VoteBox()

            // Add the @VoteBoothST.Ballot type to the list of allowed types to deposit in this collection
            voteBox.supportedTypes[self.getType()] = true

            return <- voteBox
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
        access(all) view fun getElectionOptions(): [UInt64] {
            return VoteBoothST._options
        }

        /*
            Because I have all my Ballot ownership structures neatly wrapped into a single and highly protected resource which can only be accessed by the contract owner, I need to trust that all the processes up to this point have validated that the current Ballot owner (this function runs from the Ballot resource), namely, if one and only one Ballot was minted to this account, that the contract owner has no ballots, etc.
        */
        access(all) fun vote(newOption: UInt64) {
            // Get the current owner of this ballot from the internal Ballot parameter
            let ballotOwner: Address = self.ballotOwner

            if (ballotOwner == nil) {
                // Simple consistency test, just to cover all my bases.
                panic(
                    "ERROR: Ballot #"
                    .concat(self.id.toString())
                    .concat(" does not has a owner yet!")
                )
            }

            // Another invalid situation. Deal with it
            if (ballotOwner != self.owner!.address) {
                panic(
                    "Invalid owner detected! Ballot #"
                    .concat(self.id.toString())
                    .concat(" has a different owner (function caller: ")
                    .concat(self.owner!.address.toString())
                    .concat(")")
                )
            }

            let availableOptions: [UInt64] = self.getElectionOptions()

            // Check if the option provided is valid
            if (!availableOptions.contains(newOption)) {
                // Lets transform the array of options into a String. This takes a while...

                var availableOptionsString: String = "["

                for index, option in availableOptions {
                    availableOptionsString = availableOptionsString.concat(option.toString())

                    if (index < (availableOptions.length - 1)) {
                        availableOptionsString = availableOptionsString.concat(", ")
                    }
                }
                availableOptionsString = availableOptionsString.concat("]")

                panic(
                    "ERROR: Invalid option provided: "
                    .concat(newOption.toString())
                    .concat(". Available options: ")
                    .concat(availableOptionsString)
                )
            }

            // Test the current state of the Ballot to determine (later) if this is a first vote or a re-submission
            var firstVote: Bool = true

            if (self.option != 0) {
                // The current option is not the default one anymore, which means this is a re-submission
                firstVote = false
            }

            // All validations are OK. Proceed with the vote
            self.option = newOption

            // Finish by emitting the respective event
            if (firstVote) {
                emit VoteBoothST.BallotSubmitted(_ballotId: self.id, _voterAddress: self.owner!.address)
            }
            else {
                emit VoteBoothST.BallotModified(_ballotId: self.id, _voterAddress: self.owner!.address)
            }
        }

        // Simple function that validates the caller as the owner and, if OK, returns the option parameter
        access(all) fun getVote(): UInt64? {
            let ballotOwner: Address = self.ballotOwner

            if (self.owner!.address != ballotOwner)
            {
                return nil
            }
            else{
                return self.option
            }
        }

        init(_ballotOwner: Address) {
            self.id = self.uuid
            self.option = 0
            self.ballotOwner = _ballotOwner
        }
    }
// ----------------------------- BALLOT END --------------------------------------------------------

// ----------------------------- VOTE BOX BEGIN ----------------------------------------------------
    access(all) resource VoteBox: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(contract) var supportedTypes: {Type: Bool}

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return self.supportedTypes
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            if (self.supportedTypes[type]!) {
                return true
            }

            return false
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

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            // Each one of these boxes can only hold one vote of one type at a time. Validate this
            if (self.ownedNFTs.length > 0) {
                panic(
                    "Account "
                    .concat(self.owner!.address.toString())
                    .concat(" already has a Ballot in storage")
                )
            }
            let ballot: @VoteBoothST.Ballot <- token as! @VoteBoothST.Ballot
            let randomResource: @AnyResource? <- self.ownedNFTs[ballot.id] <- ballot

            if (randomResource != nil) {
                emit NonNilTokenReturned(_tokenType: randomResource.getType())
            }

            destroy randomResource
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let ballot: @{NonFungibleToken.NFT} <- self.ownedNFTs.remove(key: withdrawID) ??
            panic(
                "No Ballots with id "
                .concat(withdrawID.toString())
                .concat(" found in storage for account ")
                .concat(self.owner!.address.toString())
            )

            return <- ballot
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            // Create the VoteBox first
            let voteBox: @VoteBoothST.VoteBox <- create VoteBoothST.VoteBox()

            // Register the Ballot type to the supported types to allow this collection to receive VoteBoothST.Ballots
            self.supportedTypes[Type<@VoteBoothST.Ballot>()] = true

            // Return the resource
            return <- voteBox
        }

        access(all) fun saySomething(): String {
            return "Hello from the inside of the VoteBoothST.VoteBox resource!"
        }

        init() {
            self.ownedNFTs <- {}
            self.supportedTypes = {}
        }
    }
// ----------------------------- VOTE BOX END ------------------------------------------------------

// Contract-level Collection creation function
access(all) fun createEmptyVoteBox(): @VoteBoothST.VoteBox {
    // Create a new VoteBox
    let voteBox: @VoteBoothST.VoteBox <- create VoteBoothST.VoteBox()

    // Set it to be able to store @VoteBoothST.Ballots
    voteBox.supportedTypes[Type<@VoteBoothST.Ballot>()] = true

    // Return it
    return <- voteBox
}

// ----------------------------- BALLOT BOX BEGIN --------------------------------------------------
/* 
    This other collection is used by this contract (because the only instance of it is stored in the contract's account) and this contract alone to store submitted ballots.
    So, to reiterate, this contract establishes 2 Collection resources: one to store a single Ballot from the voter side, another from the contract/vote booth side, to store all submitted ballots
*/
access(all) resource BallotBox: NonFungibleToken.Collection {
    access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

    access(contract) var supportedTypes: {Type: Bool}
    access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
        return self.supportedTypes
    }
    access(all) view fun isSupportedNFTType(type: Type): Bool {
        if (self.supportedTypes[type]!) {
            return true
        }

        return false
    }

    access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
        let BallotBox: @VoteBoothST.BallotBox <- create VoteBoothST.BallotBox()

        // Add the @VoteBoothST.Ballot type to allow Ballot to be deposited in this type of collection
        BallotBox.supportedTypes[Type<@VoteBoothST.Ballot>()] = true

        return <- BallotBox
    }

    // NonFungibleToken.Receiver
    access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
        let ballot: @VoteBoothST.Ballot <- token as! @VoteBoothST.Ballot

        let randomResource: @AnyResource? <- self.ownedNFTs[ballot.id] <- ballot

        if (randomResource != nil) {
            emit NonNilTokenReturned(_tokenType: randomResource.getType())
        }

        destroy randomResource
    }

    // NonFungibleToken.Collection
    access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
        let voteRef: &{NonFungibleToken.NFT}? = &self.ownedNFTs[id]

        if (voteRef != nil) {
            return voteRef
        }
        else {
            panic(
                "Unable to retrieve a valid NFT reference for token with id "
                .concat(id.toString())
                .concat(" from storage from account ")
                .concat(self.owner!.address.toString())
            )
        }
    }

    access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
        let vote: @{NonFungibleToken.NFT} <- self.ownedNFTs.remove(key: withdrawID) ??
        panic(
            "Unable to retrieve a vote with id "
            .concat(withdrawID.toString())
        )

        return <- vote
    }

    access(all) view fun saySomething(): String {
        return "Hello from inside the VoteBoothST.BallotBox resource!"
    }

    // The idea with protecting the constructor with an entitlement is to prevent users other than the deployer to create these resources
    access(Admin) init() {
        self.ownedNFTs <- {}
        self.supportedTypes = {}
        self.supportedTypes[Type<@VoteBoothST.Ballot>()] = true
    }
}

// ----------------------------- BALLOT BOX END ----------------------------------------------------

// ----------------------------- BURN BOX BEGIN ----------------------------------------------------
/*
    Okey, since I added a whole security layer around the minting and burning of Ballots (through the OwnerControl), I now have a problem: how can voter burn a Ballot in his/her VoteBox, without Admin access to a BallotPrinterAdmin, and while maintaining data consistency in the OwnerControl resource, given that, obviously, they don't have access to this resource?
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
    access(Admin) fun getBallotsToBurn(): [UInt64] {
        return self.ballotsToBurn.keys
    }

    // Simple function to determine how many ballots are set to be burn
    access(Admin) fun howManyBallotsToBurn(): Int {
        return self.ballotsToBurn.length
    }

    // This is the other important function in this resource. Think of this as the "empty garbage" button. It turns the incinerator on and burns all ballots stored in the internal dictionary. Because of access issues, I kinda need to replicate the burn function from the ballotPrinterAdmin resource
    access(Admin) fun burnAllBallots(): Void {
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
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId, _ballotOwner: ballotToBurn.ballotOwner)

                // This Ballot should not exist. In this case, check the ballotOwners dictionary and correct it before burning the Ballot
                let storedBallotOwner: Address? = ownerControlRef.getBallotOwner(ballotId: ballotToBurn.id)

                if (storedBallotOwner != nil) {
                    // Looks like there's an entry in ballotOwners dictionary for this ballot. Solve the inconsistency and move on
                    ownerControlRef.removeBallotOwner(ballotId: ballotToBurn.id, ballotOwner: storedBallotOwner!)
                }
            }
            else if (storedBallotId! != ballotToBurn.id) {
                // In this case, the owner of the ballot to burn has a different ballotId associated to it, which means that, theoretically, the owner has two ballots... somehow. In this case, emit two events with the two ballotIds and the same address and then panic... This situation is critical and needs to be taken care before moving on. Ideally this branch should nevern be called
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId!, _ballotOwner: ballotToBurn.ballotOwner)

                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotToBurn.id, _ballotOwner: ballotToBurn.ballotOwner)

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

            // All data is still consistent. Remove the related entries from both ballotOwners and owners dictionaries from the OwnerControl resource and finally burn the damn Ballot. Ish...
            ownerControlRef.removeBallotOwner(ballotId: ballotToBurn.id, ballotOwner: ballotToBurn.ballotOwner)

            ownerControlRef.removeOwner(ballotOwner: ballotToBurn.ballotOwner, ballotId: ballotToBurn.id)

            // Destroy (burn) the Ballot
            Burner.burn(<- ballotToBurn)

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
    To protect the most sensible functions of the BallotPrinterAdmin resource, namely the printBallot function, I'm protecting it with a custom 'Admin' entitlement defined at the contract level.
    This means that, in order to have the 'printBallot' and 'sot' available in a &BallotPrinterAdmin, I need an authorized reference instead of a normal one.
    Authorized references are indicated with a 'auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin' and these can only be successfully obtained from the
    'account.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(PATH)', instead of the usual 'account.capabilities.borrow...'
    Because I now need to access the 'storage' subset of the Flow API, I necessarily need to obtain this reference from the transaction signer and no one else! The transaction need to be signed by the deployed to work! Cool, that's exactly what I want!
    It is now impossible to call the 'printBallot' function from a reference obtained by the usual, capability-based reference retrievable by a simple account reference, namely, from 'let account: &Account = getAccount(accountAddress)'

    NOTE: VERY IMPORTANT
    This resource can only be used as a reference, never directly as a resource!!
    In other words, never load this, use it, and then put it back into storage. Because, not only it is extremely inefficient from the blockchain point of view, but most importantly, the resource is dangling and, as such, the self.owner!.address is going to break this due to the fact that self.owner == nil! This resource relies A LOT in knowing who the owner of the resource is (mostly because of the OwnerControl resource), so one more reason to avoid this.
*/
    access(all) resource BallotPrinterAdmin {
        // Use this parameter to store the contract owner, given that this resource is only (can only) be created in the contract constructor, and use it to prevent the contract owner from voting. It's a simple but probably necessary precaution.

        access(Admin) fun printBallot(voterAddress: Address): @Ballot {
            pre {
                // First, ensure that the contract owner (obtainable via self.owner!.address) does not match the address provided.
                self.owner!.address != voterAddress: "The contract owner is not allowed to vote!"
            }

            let newBallot: @Ballot <- create Ballot(_ballotOwner: voterAddress)

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
                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotId, _ballotOwner: voterAddress)

                panic(
                    "ERROR: The address provided ("
                    .concat(voterAddress.toString())
                    .concat(") already has a ballot with id ")
                    .concat(ballotId!.toString())
                    .concat(" issued to it!")
                )
            }

            // This one is a bit "rare", but there's a small possibility of a Ballot with the current Id was already issued, i.e., there's an address already associated to it
            let ballotOwner: Address? = ownerControlRef.getBallotOwner(ballotId: newBallot.id)

            if (ballotOwner != nil) {
                // Same as before: emit the event and panic
                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotId!, _ballotOwner: voterAddress)
                
                panic(
                    "ERROR: The Ballot Id generated ("
                    .concat(newBallot.id.toString())
                    .concat(") was already issued to address ")
                    .concat(ballotOwner!.toString())
                    .concat("!")
                )
            }

            // Seems that all went OK so far. Add the required elements to the ownerControl resource
            ownerControlRef.setBallotOwner(ballotId: newBallot.id, ballotOwner: voterAddress)
            ownerControlRef.setOwner(ballotOwner: voterAddress, ballotId: newBallot.id)

            emit BallotMinted(_ballotId: newBallot.id, _voterAddress: voterAddress)

            return <- newBallot
        }

        access(all) view fun saySomething(): String {
            return "Hello from inside the VoteBoothST.BallotPrinterAdmin Resource"
        }

        /*
            This function receives the identification number of a token that was minted by the Admin Ballot printer and removes all entries from the internal dictionaries. This is useful for when a token is burned, so that the internal contract data structure maintains its consistency.
            For obvious reasons, this function is also Admin entitlement protected. Also, I've decided to mix the burnBallot function with this one to minimize the probability of creating inconsistencies in these structures
        */
        access(Admin) fun burnBallot(ballotToBurn: @VoteBoothST.Ballot): Void {
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
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId, _ballotOwner: ballotToBurn.ballotOwner)

                // This ballot should not exist. In this case, check the other internal dictionary and correct it and burn the ballot before panicking
                let storedBallotOwner: Address? = ownerControlRef.getBallotOwner(ballotId: ballotToBurn.id)

                if (storedBallotOwner != nil) {
                    // It appears that there's a record for this ballot in the owners dictionary. Clean it to keep data consistency
                    ownerControlRef.removeBallotOwner(ballotId: ballotToBurn.id, ballotOwner: storedBallotOwner!)
                }
            }
            else if (storedBallotId! != ballotToBurn.id) {
                // The owner of the ballot to burn has a different ballotId associated to it, which means that, theoretically, the owner has two ballots... somehow. In this case, emit two events with the two ballotIds and the same address and then panic... This situation is critical and needs to be taken care before moving on. Ideally this branch should never be called
                emit VoteBoothST.ContractDataInconsistent(_ballotId: storedBallotId!, _ballotOwner: ballotToBurn.ballotOwner)

                emit VoteBoothST.ContractDataInconsistent(_ballotId: ballotToBurn.id, _ballotOwner: ballotToBurn.ballotOwner)

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
                ownerControlRef.removeBallotOwner(ballotId: ballotToBurn.id, ballotOwner: ballotToBurn.ballotOwner)

                ownerControlRef.removeOwner(ballotOwner: ballotToBurn.ballotOwner, ballotId: ballotToBurn.id)

            }

            // Destroy (burn) the Ballot finally
            Burner.burn(<- ballotToBurn)
        }

        init() {
        }
    }
// ----------------------------- BALLOT PRINTER END ------------------------------------------------

// ----------------------------- CONTRACT LOGIC BEGIN ----------------------------------------------
    
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
    access(all) view fun getElectionOptions(): [UInt64] {
        return self._options
    }

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        let voteBox: @VoteBoothST.VoteBox <- create VoteBoothST.VoteBox()

        // Add the @VoteBoothST.Ballot type to the allowed deposit types for this collection
        voteBox.supportedTypes[Type<@VoteBoothST.Ballot>()] = true

        return <- voteBox
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

// ----------------------------- CONTRACT LOGIC END ------------------------------------------------

// ----------------------------- CONSTRUCTOR BEGIN -------------------------------------------------
    init(name: String, symbol: String, ballot: String, location: String, options: String) {
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

        // Process the options string into an array
        var newOptions: [UInt64] = []
        var newInt: UInt64? = nil
        let inputOptions: [String] = options.split(separator: ";")

        for option in inputOptions {
            newInt = UInt64.fromString(option)

            if (newInt != nil) {
                newOptions.append(newInt!)
            }
            else {
                panic(
                    "VoteBoothST constructor - Found an invalid option element: "
                    .concat(option)
                )
            }
        }

        self._options = newOptions
        self.totalBallotsMinted = 0
        self.totalBallotsSubmitted = 0

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
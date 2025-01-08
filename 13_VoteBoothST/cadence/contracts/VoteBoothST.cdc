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
    access(all) let ballotCollectionStoragePath: StoragePath
    access(all) let ballotCollectionPublicPath: PublicPath
    access(all) let voteBoxStoragePath: StoragePath
    access(all) let voteBoxPublicPath: PublicPath

    // CUSTOM EVENTS
    access(all) event NonNilTokenReturned(_tokenType: Type)
    access(all) event BallotMinted(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotSubmitted(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotModified(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotBurned(_ballotId: UInt64, _voterAddress: Address)
    access(all) event ContractDataInconsistent(_ballotId: UInt64)

    // CUSTOM VARIABLES
    access(all) let _name: String
    access(all) let _symbol: String
    access(all) let _ballot: String
    access(all) let _location: String
    access(all) let _options: [UInt64]

    // I'm using these to do an internal tracking mechanism to protect this against double voting and the like
    access(all) var totalBallotsMinted: UInt64
    access(all) var totalBallotsSubmitted: UInt64
    access(contract) var ballotOwners: {UInt64: Address}
    access(contract) var owners: {Address: UInt64}

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

        access(contract) fun burnCallback() {
            emit VoteBoothST.BallotBurned(_ballotId: self.id, _voterAddress: self.ballotOwner)
        }

        access(all) view fun saySomething(): String {
            return "Hello from the VoteBoothST.Ballot Resource!"
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create VoteBoothST.VoteBox()
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
            This is one of the main ones in this system, as it should be quite obvious.
            The basis for authenticate the user with this function relies on the fact that this function needs to be called from a Ballot resource and this resource can only be created with a signed transaction. From that point onwards, any functions that consume gas get it from the transaction signer. Even if the resource is saved into storage, that storage is associated to an account. Removing that resource from storage can only be done by the owner of it. These element guarantee pretty much that this function can only be called by the owner... or the contract (this is the one scenario that I cannot dismiss right now). As such, validate if the user is the same one as one in the contract dictionaries. I have this ownership set from the contract side via a mapping/dictionary but from the voter side, this ownership is established to how Flow regulates resources, namely, that they cannot be "dangling" anywhere and must be owned by someone at all times. The function 'self.owner!.address' gives me this address
        */
        access(all) fun vote(newOption: UInt64) {
            // Get the current owner of this ballot
            let ballotOwner: Address? = VoteBoothST.getBallotOwner(ballotId: self.id)

            if (ballotOwner == nil) {
                // No record found for the current ballot. There might be ownership record issues somewhere
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
                panic(
                    "ERROR: Invalid option provided: "
                    .concat(newOption.toString())
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
        access(all) view fun getVote(): UInt64? {
            let ballotOwner: Address = VoteBoothST.getBallotOwner(ballotId: self.id)!

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
            return <- create VoteBoothST.VoteBox()
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

// ----------------------------- BALLOT COLLECTION BEGIN -------------------------------------------
/* 
    This other collection is used by this contract (because the only instance of it is stored in the contract's account) and this contract alone to store submitted ballots.
    So, to reiterate, this contract establishes 2 Collection resources: one to store a single Ballot from the voter side, another from the contract/vote booth side, to store all submitted ballots
*/
access(all) resource BallotCollection: NonFungibleToken.Collection {
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
        // TODO: Protect this function such that only the contract deployer can invoke it
        return <- create VoteBoothST.BallotCollection()
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
        return "Hello from inside the VoteBoothST.BallotCollection resource!"
    }

    init() {
        self.ownedNFTs <- {}
        self.supportedTypes = {}
        self.supportedTypes[Type<@VoteBoothST.Ballot>()] = true
    }
}

// ----------------------------- BALLOT COLLECTION END ---------------------------------------------

// ----------------------------- BALLOT PRINTER BEGIN ----------------------------------------------
    access(all) resource BallotPrinterAdmin {
        access(all) fun printBallot(voterAddress: Address): @Ballot {
            let newBallot: @Ballot <- create Ballot(_ballotOwner: voterAddress)

            emit BallotMinted(_ballotId: newBallot.id, _voterAddress: voterAddress)

            return <- newBallot
        }

        access(all) fun burnBallot(ballotToBurn: @VoteBoothST.Ballot) {
            Burner.burn(<- ballotToBurn)
        }

        access(all) view fun saySomething(): String {
            return "Hello from inside the VoteBoothST.BallotPrinterAdmin Resource"
        }

        init() {}
    }

    access(self) fun createBallotPrinterAdmin(): @VoteBoothST.BallotPrinterAdmin {
        return <- create VoteBoothST.BallotPrinterAdmin()
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

    // TODO: Not sure if it is a good idea to make the next couple of getters available for everyone.. Check this later
    access(all) view fun getBallotOwners(): {UInt64: Address} {
        return self.ballotOwners
    }
    access(all) view fun getOwners(): {Address: UInt64} {
        return self.owners
    }
    access(all) view fun getBallotOwner(ballotId: UInt64): Address? {
        return self.ballotOwners[ballotId]
    }
    access(all) view fun getBallotId(owner: Address): UInt64? {
        return self.owners[owner]
    }

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create VoteBoothST.VoteBox()
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

    /*
        This function receives the identification number of a token that was minted by the Admin Ballot printer and removes all entries from the internal dictionaries. This is useful for when a token is burned, so that the internal contract data structure maintains its consistency.
    */
    access(all) fun removeBallotOwnership(_ballotId: UInt64): Bool {
        // Get the address associated with the token id provided
        let storedAddress: Address = VoteBoothST.getBallotOwner(ballotId: _ballotId) ??
        panic(
            "Unable to get a valid address for token #"
            .concat(_ballotId.toString())
            .concat(" from the ballotOwners dictionary!")
        )

        // Remove the ballotOwners entry first
        let addressRemoved: Address = self.ballotOwners.remove(key: _ballotId) ??
        panic(
            "Unable to remove token id #"
            .concat(_ballotId.toString())
            .concat(" from the ballotOwners dictionary!")
        )

        let idRemoved: UInt64 = self.owners.remove(key: storedAddress) ??
        panic(
            "Unable to remove address "
            .concat(storedAddress.toString())
            .concat(" from the owners dictionary!")
        )

        // Validate the results before returning stuff
        if (idRemoved == _ballotId && storedAddress == addressRemoved) {
            return true
        }

        // Something else must have happened that didn't raise any of the panics above. Return false to signal that this needs to be investigated
        return false
    }

    access(all) fun burnBallot(ballotToBurn: @VoteBoothST.Ballot) {
        let result: Bool = VoteBoothST.removeBallotOwnership(_ballotId: ballotToBurn.id)

        if (!result) {
            emit ContractDataInconsistent(_ballotId: ballotToBurn.id)
        }

        Burner.burn(<- ballotToBurn)
    }
    // Add a couple of burners for the collections as well
    access(all) fun burnVoteBox(voteBoxToBurn: @VoteBoothST.VoteBox) {
        Burner.burn(<- voteBoxToBurn)
    }

// ----------------------------- CONTRACT LOGIC END ------------------------------------------------
// ----------------------------- CONSTRUCTOR BEGIN -------------------------------------------------
    init(name: String, symbol: String, ballot: String, location: String, options: String) {
        self.ballotPrinterAdminStoragePath = /storage/BallotPrinterAdmin
        self.ballotPrinterAdminPublicPath = /public/BallotPrinterAdmin
        self.ballotCollectionStoragePath = /storage/BallotCollection
        self.ballotCollectionPublicPath = /public/BallotCollection
        self.voteBoxStoragePath = /storage/VoteBox
        self.voteBoxPublicPath = /public/VoteBox

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
        self.ballotOwners = {}
        self.owners = {}

        // Clean up storage and capabilities
        let randomResource: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.ballotPrinterAdminStoragePath)

        if (randomResource != nil) {
            log(
                "Found a type '"
                .concat(randomResource.getType().identifier)
                .concat("' object in at ")
                .concat(self.ballotPrinterAdminStoragePath.toString())
                .concat(" path in account ")
                .concat(self.account.address.toString())
                .concat(" storage!")
            )
        }

        destroy randomResource

        let oldCap: Capability? = self.account.capabilities.unpublish(self.ballotPrinterAdminPublicPath)

        if (oldCap != nil) {
            log(
                "Found an active capability at "
                .concat(self.ballotPrinterAdminPublicPath.toString())
                .concat(" from account ")
                .concat(self.account.address.toString())
            )
        }

        let anotherResource: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.ballotCollectionStoragePath)

        if (anotherResource != nil) {
            log(
                "Found a type '"
                .concat(anotherResource.getType().identifier)
                .concat("' object in at ")
                .concat(self.ballotCollectionStoragePath.toString())
                .concat(" path in account ")
                .concat(self.account.address.toString())
                .concat(" storage!")
            )
        }

        destroy anotherResource

        self.account.storage.save(<- create BallotPrinterAdmin(), to: self.ballotPrinterAdminStoragePath)

        let printerCapability: Capability<&VoteBoothST.BallotPrinterAdmin> = self.account.capabilities.storage.issue<&VoteBoothST.BallotPrinterAdmin> (self.ballotPrinterAdminStoragePath)

        self.account.capabilities.publish(printerCapability, at: self.ballotPrinterAdminPublicPath)

        // Repeat the process for the BallotCollection
        self.account.storage.save(<- create BallotCollection(), to: self.ballotCollectionStoragePath)

        let ballotCollectionCap: Capability<&VoteBoothST.BallotCollection> = self.account.capabilities.storage.issue<&VoteBoothST.BallotCollection>(self.ballotCollectionStoragePath)

        self.account.capabilities.publish(ballotCollectionCap, at: self.ballotCollectionPublicPath)
    }
}
// ----------------------------- CONSTRUCTOR END ---------------------------------------------------
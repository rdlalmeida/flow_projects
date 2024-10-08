/*
    This VoteBooth contract version uses the NonFungibleToken standard, which means that I have to implement a whole set of functions and resources that I don't know, at this point, if they are going to help or get in the way (as in, they decrease the security of the system).

    The first task with this contract is making it compatible with the NonFungibleToken standard.
*/
import "NonFungibleToken"
import "Burner"

access(all) contract VoteBooth_std: NonFungibleToken {
    // STORAGE PATHS
    access(all) let ballotPrinterAdminStoragePath: StoragePath
    access(all) let ballotPrinterAdminPublicPath: PublicPath
    access(self) let ballotCollectionStoragePath: StoragePath
    access(all) let ballotCollectionPublicPath: PublicPath
    access(all) let voteBoxStoragePath: StoragePath
    access(all) let voteBoxPublicPath: PublicPath

    // CUSTOM EVENTS
    access(all) event NonNilTokenReturned(_tokenType: Type)
    access(all) event BallotMinted(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotSubmitted(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotModified(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotBurned(_ballotId: UInt64, _voterAddress: Address)

    // CUSTOM VARIABLES (These are severely restricted so I need to define getters for these parameters)
    access(all) let _name: String
    access(all) let _symbol: String
    access(all) let _ballot: String
    access(all) let _location: String
    access(all) let _options: [UInt64]

    // These variables are going to be used to keep track of votes minted and submitted
    access(all) var totalBallotsMinted: UInt64
    access(all) var totalBallotsSubmitted: UInt64

    // And this one keeps track of where the votes where sent to. This is not standard practice
    // in NFT contracts but makes sense in this particular context
    access(contract) var ballotOwners: {UInt64: Address}

    // As with the Solidity contract, I need the inverse mapping to prevent an address from getting multiple tokens
    access(contract) var owners: {Address:UInt64} 

    // Getters for the custom parameters
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

    /*
        ************************ NFT **********************************************
        The main element of this system, which in this case is set as a Resource following Flow's NonFungibleToken standard.
    */
    access(all) resource Ballot: NonFungibleToken.NFT, Burner.Burnable{
        // I want to name this id as 'ballotId' to remain consistent, but the 
        // standard doesn't want to...
        access(all) let id: UInt64

        /*
            I'm going to store the main option for the vote in this variable. For now I'm setting it as a simple Int to facilitate validations and so on, but in the interest of protecting voter privacy, this needs to be revised (any data encryption of this kind need loads of salt)
        */
        access(self) var option: UInt64

        init() {
            self.id = self.uuid

            // Set the option to an invalid value (all options are > 0) during minting
            self.option = 0
        }

        // These getters serve so that voter can access these contract parameters from their VoteNFT
        // TODO: Can I call this function when the VoteNFT is in the voter's account? I.e., when 
        // it's outside of the contract context? The compiler allows me to do this but I need to 
        // test if it does work
        access(all) view fun getElectionName(): String {
            return VoteBooth_std._name
        }

        access(all) view fun getElectionSymbol(): String {
            return VoteBooth_std._symbol
        }

        access(all) view fun getElectionLocation(): String {
            return VoteBooth_std._location
        }

        access(all) view fun getElectionBallot(): String {
            return VoteBooth_std._ballot
        }

        access(all) view fun getElectionOptions(): [UInt64] {
            return VoteBooth_std._options
        }

        /*
            This function is as pointless as they come in this context, by I need to add it. Obvioulsy I don't want the voter to create collection in the VoteBooth contract account nor I want, for now, a collection in the voter account.
        */
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create VoteBooth_std.BallotBox()
        }

        // ViewResolver.Resolver
        // Same with the next pair of functions
        access(all) view fun getViews(): [Type] {
            return []
        }

        // ViewResolver.Resolver
        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }

        /*
            I need to create a 'getVote' for both the Ballot NFT and both Collection. In each, I will have the same function signature, but it does differents things according to the spot where that happens.
        */

        /*
            This is one of the main ones in this system, as it should be quite obvious.
            The basis for autheticate the user with this function relies on the fact that this function needs to be called from a Ballot resource and this resource can only be created with a signed transaction. From that point onwards, any functions that consume gas get it from the transaction signer. Even if the resource is saved into storage, that storage is associated to an account. Removing that resource from storage can only be done by the owner of it. These element guarantee pretty much that this function can only be called by the ower... or the contract (this is the one scenario that I cannot dismiss right now). As such, validate if the user is the same one as one in the contract dictionaries. I have this ownership set from the contract side via a mapping/dictionary but from the voter side, this ownership is established to how Flow regulates resources, namely, that they cannot be "dangling" anywhere and must be owned by someone at all times. The function 'self.owner!.address' gives me this address
        */
        access(all) fun vote(newOption: UInt64) {
            // Get the current owner for this ballot
            let ballotOwner: Address? = VoteBooth_std.getBallotOwner(ballotId: self.id)

            // This situation should never happen. If it does, it means Ballot NFTs
            // are being minted outside of the owners mapping
            if (ballotOwner == nil) {
                panic("Ballot #".concat(self.id.toString()).concat(" does not has a owner yet! This token should not exist!"))
            }

            // Test if the right owner is the one that is calling this function. 
            // Panic otherwise
            if (ballotOwner != self.owner!.address) {
                panic("Invalid owner detected! Ballot #".concat(self.id.toString()).concat(" has a different owner (Function caller: ".concat(self.owner!.address.toString())).concat(")"))
            }

            // Validate the option too by matching it with one of the available options
            let availableOptions: [UInt64] = self.getElectionOptions()

            // If the option provided does not matches none of the available, panic
            if (!availableOptions.contains(newOption)) {
                panic(
                    "Invalid option provided: "
                    .concat(newOption.toString())
                    .concat(".")
                )
            }

            // Test the current state of the Ballot to determine (later) if this is
            // a first vote or a re-submission
            var firstVote: Bool = true

            if (self.option != 0) {
                // If the current option is different than the default one, it means this is a re-submission- Mark it as so
                firstVote = false 
            }

            // All validations OK. Proceed to change the ballot
            self.option = newOption

            // Emit the respective event
            if(firstVote) {
                emit VoteBooth_std.BallotSubmitted(_ballotId: self.id, _voterAddress: self.owner!.address)
            }
            else {
                emit VoteBooth_std.BallotModified(_ballotId: self.id, _voterAddress: self.owner!.address)
            }
        }

        // Simple function to print the array of options available. This one is not that efficient.
        access(all) view fun getAvailableElectionOptions(): String {
            let availableOptions: [UInt64] = self.getElectionOptions()

            var options: String = "[ "

            for option in availableOptions {
                options = options.concat(option.toString()).concat(" ")
            }

            return options.concat("]")
        }

        /*
            This function simply validates if the caller is the Ballot NFT owner and, if it is, return the current value of the option parameter. Return nil otherwise
        */
        access(all) view fun getVote(): UInt64? {
            // Force the optional out of this one because, at this point, there are little chance of getting a nil with this one
            let ballotOwner: Address = VoteBooth_std.getBallotOwner(ballotId: self.id)!

            if (self.owner!.address != ballotOwner) {
                return nil
            }
            else {
                return self.option
            }
        }

        /*
            Now for the things to properly implement the Burner interface so that voters have the ability to burn their Ballot NFTs if, by whatever reason, they want to retract a submitted vote. At this level (at the NFT level) I need to establish the burnCallback function to be automatically triggered when the token is burned/destroyed (apparently the new Crescendo upgrade remove the resource's default destructor and this callback tries to re establish some of its functionalities.)
        */
        access(contract) fun burnCallback() {
            // For now, all I care is to emit the event that signals the token burn
            emit VoteBooth_std.BallotBurned(_ballotId: self.id, _voterAddress: self.owner!.address)
        }

        access(all) view fun saySomething(): String {
            return "Hello from the VoteBooth_std.Ballot Resource!"
        }
    }
    // ************************ NFT **********************************************


    /*
        ******************** MINTER **********************************************
        Use this Admin resource to manage access to the BallotPrinter
        The idea is to protect the creation of Ballot NFTs with two layers and based in one fundamental aspect: resources can only be created within contracts! In other words, only contract function are allowed to create resources. It is impossible to create a resource directly with a transaction (literally executing 'create <Resource>'), so, in order to create a resource implemented by a contract, we need a function that, internally, uses the 'create' instruction and then returns the Resource.
        That said, by restricting both the Ballot creation function and the function to create the ballotPrinter (but not the Printer resource because I can't). This means that only the contract deployer account can run both the Printer creation and the Ballot printing.
        Finally, as it is usually the rule, create and save a printer in the contract contructor.
    */
    access(all) resource BallotPrinterAdmin {
        // TODO: I don't like these permissions a bit! Test this extensively! I need to be 100% sure some dude cannot borrow this thing and starts printing ballots left and right.
        access(all) fun printBallot(voterAddress: Address): @Ballot {
            // Before minting the Ballot NFT, check if the voterAddress already has another minted into its account
            pre{VoteBooth_std.owners[voterAddress] == nil: "Voter account ".concat(voterAddress.toString()).concat(" already has a Ballot.")}

            // Fill out the contract mappings before returning the Ballot NFT
            let newBallot: @Ballot <- create Ballot()

            VoteBooth_std.owners[voterAddress] = newBallot.id
            VoteBooth_std.ballotOwners[newBallot.id] = voterAddress

            // Emit the respective event
            emit BallotMinted(_ballotId: newBallot.id, _voterAddress: voterAddress)

            // Return the ballot to the owner
            return <- newBallot
        }

        access(all) view fun saySomething(): String {
            return "Hello from inside the VoteBooth_std.BallotPrinterAdmin Resource"
        }
    }

    access(self) fun createBallotPrinterAdmin(): @VoteBooth_std.BallotPrinterAdmin {
        return <- create VoteBooth_std.BallotPrinterAdmin()
    }
    // ************************ MINTER ********************************************

    /*
        ************************ BALLOT COLLECTION ********************************
        The idea with this Resource is it to be used to store the votes from the contract side, i.e., after they were submitted. The idea is for the voters not having these collections (for now at least) since I can use the storage domains as a handy way to guarantee that, at any point, each voter has only one vote in his/her account storage.

        I'm creating two types of Collections in this contract. The BallotBox is the one that sits in the contract account and can hold multiple voteNFTs, which count as submitted votes. The VoteBox is another collection that sits in the voter's account and is limited to hold only one VoteNFT at a time. Votes minted go into a VoteBox and once submitted they go into the BallotBox Collections.
    */
    access(all) resource BallotBox: NonFungibleToken.Collection {
        /* 
            This dictionary is going to be used to store the submitted votes. Ideally this structure should have a more suggestive name, but that is impossible if the NonFungibleToken standard is to be followed.
            // TODO: It's getting clearer and clearer that, at some point, I need to create my own standard for this purpose.
        */
        // NonFugibleToken.Collection
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        // I'm going to use this dictionary to store the NFT types supported by the collections in 
        // this contract. This another of those standard requirements
        access(contract) var supportedTypes: {Type: Bool}

        // NonFungibleToken.Receiver
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return self.supportedTypes
        }

        // NonFungibleToken.Receiver
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            // The '!' is used to resolve a potential Bool?
            if (self.supportedTypes[type]!) {
                // This function only 'tells' if a type is supported or not with a Bool
                return true
            }

            return false
        }

        // NonFungibleToken.Collection
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            /*
                I can do this, i.e., return a @VoteBooth.BallotBox resource when the function specifies that the return type is @{NonFungibleToken.Collection} because the BallotBox is a sub type of the wider Collection type.
            */
            return <- create VoteBooth_std.BallotBox()
        }

        // NonFungibleToken.Receiver
        /*
            Because I want to follow the NonFungibleToken standard in this particular implementation, I need to restrict the number of deposits that can be done, namely prevent that multiple VoteNFTs can be deposited into one account. I can use the voteOwners dictionary
        */
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {    
                    
            // Force-cast the token received to the expected type
            let ballot: @VoteBooth_std.Ballot <- token as! @VoteBooth_std.Ballot

            // Save the VoteNFT in the spot determined by its id and save whatever may be in that
            // dicionary entry to a variable. If all goes right, this variable should be 'nil'
            let randomResource: @AnyResource? <- self.ownedNFTs[ballot.id] <- ballot

            // But let's test it anyhow
            if (randomResource != nil) {
                // If something other than a 'nil' was obtained, emit the respective event and move on
                emit NonNilTokenReturned(_tokenType: randomResource.getType())
            }

            // Destroy the variable before exiting
            destroy randomResource
        }

        // NonFungibleToken.Collection
        /*
            I can use this function to check out the contents of a VoteNFT. The voter can use it also for verifiability purposes. At some point, the vote contents need to be encrypted and all the verifiability logic seriously revised.
            NOTE: The '_' as function argument means that, when invoked, the argument doesn't need to be preempted, i.e., the function can be called as 'borrowNFT(12)' or 'borrowNFT(id: 12)'
            TODO: Use the 'borrowNFT' function as base to analyse and implement Verifiability.
        */
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            /*
                Grab a reference to the VoteNFT but not the token itself. This is kinda of a copy of the token parameters but for read-only purposes. The standard implies that I need to return whatever is in the dictionary position, which may be a nil (hence why the return as that '?'). I cannot protect against that at this level so I need to take this into account when requesting this reference.
            */
            let voteRef: &{NonFungibleToken.NFT}? = &self.ownedNFTs[id]

            return voteRef
        }

        // NonFungibleToken.Provider
        /*
            This another of those functions that, ideally should be used only be the vote owner and by the VoteBooth and Tally contracts. These entities need to be the only one able to move a VoteNFT from one account to another.
            TODO: Test the restrictions of this function: only the VoteNFT onwer, the VoteBooth and the Tally contract should be able to use this function and even those uses are restricted to Voter <-> VoteBooth and VoteBooth <-> Tally
        */
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let vote: @{NonFungibleToken.NFT} <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Unable to retrive a vote with id ".concat(withdrawID.toString()))

            return <- vote
        }

        access(all) view fun saySomething(): String {
            return "Hello from inside the VoteBooth_std.BallotBox Resource!"
        }

        init() {
            self.ownedNFTs <- {}

            // Initialize the supported types dictionary
            // NOTE: This one is a simple dicionary. No resources involved, 
            // therefore it gets a '=' instead of a '<-'
            self.supportedTypes = {}

            // And add to it the only NFT type to ever be supported
            self.supportedTypes[Type<@VoteBooth_std.Ballot>()] = true
        }
    }
    // ************************ BALLOT COLLECTION *********************************

    /*  
        ************************ VOTE COLLECTION **********************************
        This one is the collection intended to store a single VoteNFT in the voter account. Since I can (need to) add a createEmptyCollection function to both the contract and the NFT implementation, the contract function creates the BallotBox and the NFT one creates the VoteBox. A ballot becomes a vote once the voter choses an option.
        This resource also follows the NonFungibleToken.Collection standard, therefore I need to implement a bunch of paramters that actually force me to adapt this Collection to serve my needs.
    */
    access(all) resource VoteBox: NonFungibleToken.Collection {
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

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            // Test if there are no other votes in storage thus far. Panic if so
            if (self.ownedNFTs.length > 0) {
                panic("Account ".concat(self.owner!.address.toString()).concat(" already has a VoteNFT in storage"))
            }
            let ballot: @VoteBooth_std.Ballot <- token as! @VoteBooth_std.Ballot

            let randomResource: @AnyResource? <- self.ownedNFTs[ballot.id] <- ballot

            if (randomResource != nil) {
                /* 
                    TODO: Test if this event gets emitted (probably need to force it). In theory this should not be possible once this resource is stored somewhere, under the assumption that it does not has access to the contract parameters, namely the event definition
                */
                emit NonNilTokenReturned(_tokenType: randomResource.getType())
            }

            destroy randomResource
        }

        /*
            Since I expect that only one VoteNFT should be stored in this collection, it should be redundant to provide an argument when calling it. But because the standard requires so, I need to keep the function signature like this and then adapt its insides to my needs.
            This function returns a &{NonFungibleToken.NFT}?, i.e., an optional (that's what the '?' is for) reference to a NonFungibleToken.NFT resource. This means that, if the resource does exists is storage (we are never 100% sure), the reference is returned. Otherwise, the '?' allows for a nil to be returned if no token exists in storage yet.
        */
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            /*
                The way I've written this, there should be only one VoteNFT in storage, max. So, either self.ownedNFTs[0] either exists or not. If there's nothing in position 0 (no VoteNFTs minted to that account yet), trying to get a reference to a non-filled position returns a nil, which is OK in this context. So, to simplify things simply try to return the token at key = 0 and that is enough for now. But the main issue remains: I don't need to use the input argument.
            */
            // Set the id provided as input to the only expectable index in the internal dictionary
            // This is as close to a function overwrite as I ever been close to.
            let id: UInt64 = 0

            let voteRef: &{NonFungibleToken.NFT}? = &self.ownedNFTs[id]

            return voteRef
        }

        // NonFungibleToken.Collection
        /*
            This function is the main one used to submit the vote, namely to transfer the VoteNFT from the voter's account to the contract account, i.e., this function should be limited to one direction only. The voter can 'withdraw' a filled out VoteNFT back to the VoteBooth contract but the inverse should not be possible.
            TODO: Validate that the user can only withdraw a filled out token and nothing else other than that 
        */
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            /*
                Try to get the token identified and panic if it does not exist. Once again, the
                expectation for this specific case is that either no VoteNFTs exist in storage or a single one at index 0. Any case other than these two should be treated as an error.
                As with other functions thus far, the NonFungibleToken standard requires me to add an input argument to the withdraw function, but internally this argument is overwritten.
            */
            // Overwrite this one as well
            let withdrawID: UInt64 = 0
            let ballot: @{NonFungibleToken.NFT} <- self.ownedNFTs.remove(key: withdrawID) ??
            // Panic if the user does not have a token in storage yet
            panic("No VoteNFTs found in storage for account ".concat(self.owner!.address.toString()))

            // Done. Send the vote back
            return <- ballot
        }

        /*
            This one is the function that creates a Collection into the voter's storage account. I need to make sure that only eligible voters are able to call this function and that it gets stored directly to their account.
            TODO: Test that only eligible voters can create empty collections
            TODO: Test/Ensure that these collections can only be saved in the voter's storage account
            TODO: Establish another Eligibility step here as well 
        */
        // NonFungibleToken.Collection
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            // TODO: Validate that the msg.sender is a eligible voter and not a contract HERE
            return <- create VoteBooth_std.VoteBox()
        }

        // Add the Ballot burner function here too. This should allow the voter to call it from its VoteBox collection if it does not has access to the contract
        access(all) fun burnBallot(ballotToBurn: @VoteBooth_std.Ballot) {
            Burner.burn(<- ballotToBurn)
        }

        access(all) view fun saySomething(): String {
            return "Hello from the inside of the VoteBooth_std.VoteBox Resource!"
        }

        init() {
            self.ownedNFTs <- {}
            self.supportedTypes = {}
            self.supportedTypes[Type<@VoteBooth_std.Ballot>()] = true
        }
    }

    // I need a function to create these ones as well
    access(all) fun createEmptyVoteBox(): @VoteBooth_std.VoteBox {
        // The collection that stores the Ballots themselves is harmless in itself
        return <- create VoteBooth_std.VoteBox()
    }
    // ************************ VOTE COLLECTION ***********************************

    
    // NonFungibleToken.Collection
    /*
        This one is another of the standard requirements, include providing the type of the NFT to store in the collection. This one is a bit useless... for now.
    */
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        // I need to create a Collection resource first to be able to use its
        // type tester function
        let ballotBox: @VoteBooth_std.BallotBox <- create BallotBox()

        // Use it to test if the input type is a valid one
        if (ballotBox.isSupportedNFTType(type: nftType)) {
            // All is OK. Return the ballot box created
            return <- ballotBox
        }
        else {
            // Otherwise, destroy the ballotBox and panic
            destroy ballotBox
            panic("This contract does not supports NFTs from type ".concat(nftType.identifier).concat("!"))
        }
    }

    // The following function are a bit useless for now, but I need to set them.. 
    // because of the standard, as usual
    // ViewResolver
    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        // Return nothing, for now
        // TODO: Review if these functions may have some use in the e-voting context
        return []
    }

    // ViewResolver
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        return nil
    }

    /*
        Simple function to return the address of the owner of token with the id provided, or nil if none exists yet
    */
    access(all) view fun getBallotOwner(ballotId: UInt64): Address? {
        return self.ballotOwners[ballotId]
    }

    /*
        Another simple function to return the id of the ballot that was tranferred to the address provided
    */
    access(all) view fun getBallotId(owner: Address): UInt64? {
        return self.owners[owner]
    }

    /*
        And here I need to add the actual burn function, which is going to be at the contract and at the collection level
    */
    access(all) fun burnBallot(ballotToBurn: @VoteBooth_std.Ballot) {
        // Call the parent's function and get on with it
        Burner.burn(<- ballotToBurn)

        /*
            TODO: The expectation is that, if I call this burn function, at some point, the burnCallback that I defined in the Ballot NFT specification is going to be called too down the line. It should emit the BallotBurned event. Test this!
        */
    }

    // Just for consistency, add two new burner functions at this level: one for BallotBox Collections and another for the VoteBox Collections
    // I could have one function for both purposes, but good programming practices require this kind of specification
    // I don't expect these function to ever be needed, but just in case...
    access(all) fun burnBallotBox(ballotBoxToBurn: @VoteBooth_std.BallotBox) {
        Burner.burn(<- ballotBoxToBurn)
    }

    access(all) fun burnVoteBox(voteBoxToBurn: @VoteBooth_std.VoteBox) {
        Burner.burn(<- voteBoxToBurn)
    }

    access(all) view fun saySomething(): String {
        return "Hello from the VoteBooth_std.cdc contract level!"
    }

    /*
        The constructor for the contract (not the NFTs). This one receives a string and sets it has the main ballot, i.e., what this election is all about

        TODO: Investigate how Flow solves the ownership issue regarding this contract, for instance. In Solidity we have the Ownable modifier and onlyOwner stuff, but this is not as clear in Flow thus far
    */
    init(name: String, symbol: String, ballot: String, location: String, options: [UInt64]) {
        self.ballotPrinterAdminStoragePath = /storage/BallotPrinterAdmin
        self.ballotPrinterAdminPublicPath = /public/BallotPrinterAdmin
        self.ballotCollectionStoragePath = /storage/BallotBox
        self.ballotCollectionPublicPath = /public/BallotBox
        self.voteBoxStoragePath = /storage/VoteBox
        self.voteBoxPublicPath = /public/VoteBox

        // Use the input arguments to set the internal parameters
        self._name = name
        self._symbol = symbol
        self._ballot = ballot
        self._location = location
        self._options = options

        // Initialize the vote counting variables
        self.totalBallotsMinted = 0
        self.totalBallotsSubmitted = 0
        self.ballotOwners = {}
        self.owners = {}

        // Create and save the one VoteNFTMinter into the contract's own account
        self.account.storage.save(<- create BallotPrinterAdmin(), to: self.ballotPrinterAdminStoragePath)

        // Go ahead and create an empty BallotBox Collection and store it as well
        self.account.storage.save(<- create BallotBox(), to: self.ballotCollectionStoragePath)

        // Create a capability to a BallotPrinter public path to avoid having to load this resource every time I need to print a Ballot
        // TODO: Check that this capability allows the contract AND ONLY the contract to run the printBallot function
        
        // TODO: Do I really need to do this? Apparently with the new upgrade, the owner of the reference is allowed to borrow it directly from his/her own storage...
        // let printerCapability: Capability<&VoteBooth_std.BallotPrinterAdmin> = self.account.capabilities.storage.issue<&VoteBooth_std.BallotPrinterAdmin>(self.ballotPrinterAdminStoragePath)

        // self.account.capabilities.publish(printerCapability, at: self.ballotPrinterAdminPublicPath)
    }
}
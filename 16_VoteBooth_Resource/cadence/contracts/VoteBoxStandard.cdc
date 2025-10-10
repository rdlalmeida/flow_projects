/**
    ## The VoteBox Resource standard

    The interface that regulates the VoteBox resource and usage. VoteBoxes are resources that give to a voter their ability to interact with this application using the methods exposed by this resource. As it has been the case so far, I'm using Interfaces to establish standards for every resource implemented in this process.

    # Author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "Burner"
import "BallotStandard"
import "ElectionStandard"

access(all) contract VoteBoxStandard {
    // CUSTOM PATHS
    access(all) let voteBoxStoragePath: StoragePath
    access(all) let voteBoxPublicPath: PublicPath

    // CUSTOM ENTITLEMENTS
    access(all) entitlement VoteBoxAdmin

    // CUSTOM EVENTS
    // This event emits when a VoteBox is burned using the Burner contract. The idea is to reveal only the electionIds that this VoteBox has been used to 
    // submit Ballots (the _electionsVoted array), as well as the list of active Ballots, or better, the electionIds for the Elections that this VoteBox
    // has an active Ballot in it
    access(all) event VoteBoxDestroyed(_electionsVoted: [UInt64], _activeBallots: Int, _voterAddress: Address)

    // The public version of the VoteBox resource that only exposes the depositBallot function
    access(all) resource interface VoteBoxPublic {
        access(all) let voteBoxId: UInt64
        access(VoteBoxStandard.VoteBoxAdmin) fun depositBallot(ballot: @BallotStandard.Ballot): Void
        access(all) view fun getElectionName(electionId: UInt64): String?
        access(all) view fun getElectionBallot(electionId: UInt64): String?
        access(all) view fun getElectionOptions(electionId: UInt64): {UInt8: String}?
        access(all) view fun getElectionPublicKey(electionId: UInt64): [UInt8]?
        access(all) view fun getElectionTotalBallotsMinted(electionId: UInt64): UInt?
        access(all) view fun getElectionTotalBallotsSubmitted(electionId: UInt64): UInt?
    }
    
    access(all) resource VoteBox: Burner.Burnable, VoteBoxPublic {
        access(all) let voteBoxId: UInt64
        // Internally, I want this VoteBox to store only one Ballot per Election. As such, I'm using the Ballot's electionId index as key for the
        // internal dictionary, i.e., the UInt64 used as key in this dictionary relates to the linkedElectionId parameter from the Ballot itself.
        access(self) var activeBallots: @{UInt64: BallotStandard.Ballot}

        // This array stores all the electionIds for submitted Ballots, regardless of their outcome, i.e., even if a voter revokes their Ballot at a later
        // stage, the electionId of that Election is still stored here. This is merely a statistical parameter to provide feedback to the voter more than
        // anything. This array stored the electionId whenever a Ballot is submitted to a given Election.
        access(self) var electionsVoted: [UInt64]

        // This parameter may seem a bit of overkill, but I want to prevent voters from transferring their VoteBox resource to another account, which they 
        // are allowed to do according to Cadence rules. I cannot prevent this but I can prevent this resource from functioning properly if at any
        // point the address of the account storage differs from the one set with the resource constructor, the voter is prevented from accessing and
        // invoking functions.
        access(self) let voteBoxOwner: Address

        /**
            Function to abstract the validation step hat also retrieves a reference to the Ballot in storage, for the provided electionId, and grabs a public reference to the Election resource associated to the Ballot.

            @param electionId (UInt64) The Election identifier associated to the Ballot to retrieve from among the active ones.

            @returns (&{ElectionStandard.ElectionPublic}?) If a valid Ballot was retrieved from the electionId provided, and a valid Election was found referenced by it, this function returns the public reference to the Election in question. If any of these steps fails, the function returns nil instead
        **/
        access(self) view fun getPublicElectionReference(electionId: UInt64): &{ElectionStandard.ElectionPublic}? {
            let ballotRef: &BallotStandard.Ballot? = &self.activeBallots[electionId]

            if (ballotRef == nil) {
                // No Ballots found for that electionId. Return a nil instead.
                return nil
            }
            else {
                // Grab the public reference for the Election associated to this Ballot
                // First force cast the Ballot's capability to the right type of Capability
                let electionPubCap: Capability<&{ElectionStandard.ElectionPublic}> = ballotRef!.getElectionCapability() as! Capability<&{ElectionStandard.ElectionPublic}>

                let electionRef: &{ElectionStandard.ElectionPublic} = electionPubCap.borrow() ??
                panic(
                    "Unable to retrieve a valid &{ElectionStandard.ElectionPublic} from the electionCapability set in Ballot "
                    .concat(ballotRef!.ballotId.toString())
                    .concat(" in the VoteBox for account ")
                    .concat(self.owner!.address.toString())
                )

                // Done. Return the reference
                return electionRef
            }
        }

        /**
            Function to retrieve the name of the Election associated to the Ballot retrieved with the input argument.

            @param electionId (UInt64) The electionId used to retrieve a reference to the Ballot from the internal activeBallots dictionary.

            @returns (String) If a Ballot exists under the provided electionId, this function returns the name of the Election associated to it. Otherwise, it returns a nil.
        **/
        access(all) view fun getElectionName(electionId: UInt64): String? {
            let electionRef: &{ElectionStandard.ElectionPublic}? = self.getPublicElectionReference(electionId: electionId)

            if (electionRef == nil) {
                return nil
            }
            else {
                return electionRef!.getElectionName()
            }
        }

        /**
            Function to retrieve the ballot for the Election associated to the Ballot retrieved with the input argument.

            @param electionId (UInt64) The electionId used to retrieve a reference to the Ballot from the internal activeBallots dictionary.

            @returns (String) If a Ballot exists under the provided electionId, this function returns the name of the Election associated to it. Otherwise, it returns a nil.
        **/
        access(all) view fun getElectionBallot(electionId: UInt64): String? {
            let electionRef: &{ElectionStandard.ElectionPublic}? = self.getPublicElectionReference(electionId: electionId)

            if (electionRef == nil) {
                return nil
            }
            else {
                return electionRef!.getElectionBallot()
            }
        }

        /**
            Function to retrieve the set of available ballot options for the Election associated to the Ballot retrieved with the input argument.

            @param electionId (UInt64) The electionId used to retrieve a reference to the Ballot from the internal activeBallots dictionary.

            @returns ({UInt8: String}?) If a Ballot exists under the provided electionId, this function returns a {UInt8: String} with an option index as key and the option text as value, for the Election associated to it. Otherwise, it returns a nil.
        **/
        access(all) view fun getElectionOptions(electionId: UInt64): {UInt8: String}? {
            let electionRef: &{ElectionStandard.ElectionPublic}? = self.getPublicElectionReference(electionId: electionId)

            if (electionRef == nil) {
                return nil
            }
            else {
                return electionRef!.getElectionOptions()
            }
        }

        /**
            Function to retrieve the public encryption key, as an array of UInt8 values, for the Election associated to the Ballot retrieved with the input argument.

            @param electionId (UInt64) The electionId used to retrieve a reference to the Ballot from the internal activeBallots dictionary.

            @returns ([UInt8]) If a Ballot exists under the provided electionId, this function returns an array of UInt8 values encoding the public encryption key of the Election associated to it. Otherwise, it returns a nil.
        **/
        access(all) view fun getElectionPublicKey(electionId: UInt64): [UInt8]? {
            let electionRef: &{ElectionStandard.ElectionPublic}? = self.getPublicElectionReference(electionId: electionId)

            if (electionRef == nil) {
                return nil
            }
            else {
                return electionRef!.getPublicEncryptionKey()
            }
        }

        /**
            Function to retrieve the total number of minted Ballots for the Election associated to the Ballot retrieved with the input argument.

            @param electionId (UInt64) The electionId used to retrieve a reference to the Ballot from the internal activeBallots dictionary.

            @returns (UInt) If a Ballot exists under the provided electionId, this function returns the total for ballots minted to the Election associated to it. Otherwise, it returns a nil.
        **/
        access(all) view fun getElectionTotalBallotsMinted(electionId: UInt64): UInt? {
            let electionRef: &{ElectionStandard.ElectionPublic}? = self.getPublicElectionReference(electionId: electionId)

            if (electionRef == nil) {
                return nil
            }
            else {
                return electionRef!.getTotalBallotsMinted()
            }
        }

        /**
            Function to retrieve the total number of submitted Ballots for the Election associated to the Ballot retrieved with the input argument.

            @param electionId (UInt64) The electionId used to retrieve a reference to the Ballot from the internal activeBallots dictionary.

            @returns (UInt) If a Ballot exists under the provided electionId, this functions returns the total of ballots submitted to the Election associated to it. Otherwise, it returns a nil.
        **/
        access(all) view fun getElectionTotalBallotsSubmitted(electionId: UInt64): UInt? {
            let electionRef: &{ElectionStandard.ElectionPublic}? = self.getPublicElectionReference(electionId: electionId)

            if (electionRef == nil) {
                return nil
            }
            else {
                return electionRef!.getTotalBallotsSubmitted()
            }
        }

        /**
            This function is used to abstract the validation step for the remaining getter function. Before attempting any of the following getters I need:
            1. This VoteBox needs to have a valid Ballot stored under the electionId provided. NOTE: The internal activeBallots dictionary uses electionIds as keys to store Ballots.
            2. The Election in question needs to have a valid Capability<&{ElectionStandard.ElectionPublic}> set in it

            This function abstracts the steps to ensure these two steps

            @param electionId (UInt64) The election identifier to retrieve the desired Election resource.

            @return (Bool) True if the getter function can proceed, False otherwise.
        **/
        access(self) view fun validateElection(electionId: UInt64): Bool {
            let targetBallotRef: &BallotStandard.Ballot? = &self.activeBallots[electionId]

            if (targetBallotRef == nil) {
                return false
            }
            else {
                if (targetBallotRef!.getElectionCapability() == nil) {
                    return false
                }
                else {
                    return true
                }
            }
        }

        /**
            Simple getter to retrieve the current option set. This is inoffensive since the String returned is the blinded ciphertext. The only information leaked is if the current Ballot was set or not.

            @param electionId (UInt64) The election identifier for the Ballot whose vote is to be retrieved.

            @returns String The current option set in the Ballot resource identified by the electionId provided. Returns nil if there no Ballot for the electionId supplied.
        **/
        access(BallotStandard.BallotAdmin) view fun getVote(electionId: UInt64): String? {
            let ballotRef: auth(BallotStandard.BallotAdmin) &BallotStandard.Ballot? = &self.activeBallots[electionId]

            if (ballotRef == nil) {
                return nil
            }
            else {
                return ballotRef!.getOption()
            }
        }

        /**
            Function to set the option field in a Ballot stored in this VoteBox. This function activates the one at Ballot.vote, which is protected with same entitlement as this one, for obvious consistency.
            NOTE: This function DOES NOT deliver the Ballot anywhere, it only changes the resource's option metadata parameter.

            @param electionId (UInt64) The Election identifier for the Ballot that is to be set to.
            @param newOption (String) The new option to set the Ballot to. The assumption is that this function is to be invoked from a frontend application that has blinded and encrypted the option already, so this String is supposed to be a ciphertext.
        **/
        access(BallotStandard.BallotAdmin) fun setOption(electionId: UInt64, newOption: String): Void {
            // This function does not does anything to the dictionary of active Ballots. Make sure that this situation is consistent
            pre {
                self.activeBallots[electionId] != nil: "There are no Ballots for election ".concat(electionId.toString()).concat(" currently in storage!")
            }
            post {
                self.activeBallots[electionId] != nil: "Missing the set Ballot for election ".concat(electionId.toString()).concat(" currently in storage!")
            }

            // Set the option of the Ballot in question without removing it from the internal dictionary
            let ballotRef: auth(BallotStandard.BallotAdmin) &BallotStandard.Ballot? = &self.activeBallots[electionId]

            // I've ensured with the pre-condition that the Ballot whose option I want to set exists, so I can force cast it safely
            ballotRef!.vote(newOption: newOption)

        }

        /**
            Function to deliver the Ballot to the Election resource whose reference is obtainable through the Ballot's electionCapability parameter. The electionId argument is used to retrieve the Ballot from internal storage. If there's none, the relevant event is emitted instead.

            @param electionId (UInt64) The Election identifier for the Ballot that is to be be cast.
        **/
        access(BallotStandard.BallotAdmin) fun castBallot(electionId: UInt64): Void {
            // Similar to the "setOption" function, this one checks initially if a Ballot with the provided electionId already exists before continuing
            pre {
                self.activeBallots[electionId] != nil: "There are no Ballot for election ".concat(electionId.toString()).concat(" currently in storage!")
            }

            // When this function finishes, there shouldn't be any Ballots under the provided electionId
            post {
                self.activeBallots[electionId] == nil: "Ballot ".concat(electionId.toString()).concat(" should have been submitted. Cannot continue!")
            }

            let ballotToSubmit: @BallotStandard.Ballot <- self.activeBallots.remove(key: electionId) ??
            panic(
                "Unable to retrieve a valid @BallotStandard.Ballot from the VoteBox from account "
                .concat(self.owner!.address.toString())
                .concat(" with electionId ")
                .concat(electionId.toString())
            )

            // Got a valid Ballot. Use its PublicElection reference electionCapability to get a reference to the Election to submit this thing to
            // TODO: Not sure if this shit works... an authorized reference to a public capability? Seems fishy... this needs testing ASAP
            let electionReference: auth(BallotStandard.BallotAdmin) &{ElectionStandard.ElectionPublic} = ballotToSubmit.electionCapability.borrow<auth(BallotStandard.BallotAdmin) &{ElectionStandard.ElectionPublic}>() ??
            panic(
                "Unable to retrieve a valid &{ElectionStandard.ElectionPublic} from the electionCapability from Ballot "
                .concat(ballotToSubmit.ballotId.toString())
                .concat(" with electionId ")
                .concat(electionId.toString())
            )

            // Use the reference to access the "submitBallot" function and send the Ballot to the Election where it belongs
            electionReference.submitBallot(ballot: <- ballotToSubmit)

            // Add the electionId provided to the votedElections array
            self.electionsVoted.append(electionId)
        }

        /**
            This function is supposed to be exposed by the VoteBoxPublic interface and should be used by an Admin entity to deliver a requested Ballot into this VoteBox. Obviously, the printing of new Ballots is heavily regulated in this process and can only be invoked by Admin level people. But these also need a way to deliver the Ballot into one of these VoteBoxes. This is the function they should use for the effect.
            To prevent idiots from importing the BallotStandard contract and deliver Ballots at will to unsuspecting voters, this function is protected with the VoteBooth.VoteBoothAdmin entitlement, which requires an authorized reference to this VoteBox to do anything.
            I've protected this function with this contract's entitlement, namely, VoteBoxStandard.VoteBoxAdmin on the hopes of guaranteeing that only the deployer of this contract can deposit Ballots into other voter's VoteBoxes.

            @param ballot (@BallotStandard.Ballot) The Ballot resource to deposit in this VoteBox
        **/
        access(VoteBoxStandard.VoteBoxAdmin) fun depositBallot(ballot: @BallotStandard.Ballot): Void {
            // Check and panic if, by whatever reason, there's a Ballot already with the provided electionId
            pre {
                self.activeBallots[ballot.linkedElectionId] == nil: "The VoteBox in account ".concat(self.owner!.address.toString()).concat(" already has a Ballot under electionId ").concat(ballot.linkedElectionId.toString())
                // Validate that the Ballot being deposited has the same owner as this VoteBox resource
                ballot.voterAddress == self.owner!.address: "ERROR: Ballot with owner ".concat(ballot.voterAddress.toString()).concat(" is trying to be deposited onto voter ").concat(self.owner!.address.toString()).concat(" account. These addresses must match!")
            }

            // Clean up the storage slot and deposit the new Ballot
            let phantomResource: @AnyResource? <- self.activeBallots[ballot.linkedElectionId] <- ballot
            destroy phantomResource
        }

        /**
            This function retrieves all active Ballots from the activeBallots dictionary and burns them one by one with the Burner contract so that the respective burnCallback is called for each destroyed Ballot.
        **/
        access(contract) fun burnCallback(): Void {
            let ballotKeys: [UInt64] = self.activeBallots.keys
            let ballotsBurned: Int = self.activeBallots.length

            for ballotKey in ballotKeys {
                let ballotToBurn: @BallotStandard.Ballot? <- self.activeBallots.remove(key: ballotKey)

                // Destroy every Ballot individually
                Burner.burn(<- ballotToBurn)
            }
        }

        // TODO: REDO this constructor descriptor
        // VoteBox resource constructor
        init(_voteBoxOwner: Address) {
            self.voteBoxId = self.uuid
            self.activeBallots <- {}
            self.electionsVoted = []
            self.voteBoxOwner = _voteBoxOwner
        }
    }

    /**
        The usual builder function for VoteBox resources.

        @return (@VoteBoxStandard.VoteBox) A brand new VoteBox resource.
    **/
    access(all) fun createVoteBox(newVoteBoxOwner: Address): @VoteBoxStandard.VoteBox {
        return <- create VoteBoxStandard.VoteBox(_voteBoxOwner: newVoteBoxOwner)
    }

    // Contract constructor
    init() {
        self.voteBoxStoragePath = /storage/voteBox
        self.voteBoxPublicPath = /public/voteBox
    }
}
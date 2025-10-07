/**
    ## The Ballot Token standard

    Interface to regulate the access to the base resource for this project, namely, the Ballot.

    @author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "Burner"
import "Crypto"

access(all) contract BallotStandard {
// CUSTOM ENTITLEMENTS
    access(all) entitlement BallotAdmin

    // CUSTOM EVENTS
    access(all) event BallotBurned(_ballotId: UInt64, _linkedElectionId:UInt64)

    access(all) resource interface BallotPublic {
        access(all) let ballotId: UInt64
        access(all) let linkedElectionId: UInt64
        access(all) view fun getElectionName(): String
        access(all) view fun getElectionBallot(): String
        access(all) view fun getElectionOptions(): {UInt8: String}
        access(all) view fun getOption(): String
    }

    access(all) resource Ballot: Burner.Burnable {
        access(all) let ballotId: UInt64
        access(all) let linkedElectionId: UInt64
        /**
            This capability is going to be used to access the "submitBallot" function from the Election resource that points to it. The idea is to keep Election resources somewhat hidden in the VoteBooth deployer account and delegate access to it on a per-voter basis, using the Ballot resources to that effect.
        */
        access(BallotAdmin) let electionCapability: Capability
        /**
            This is the field where the choice in the ballot gets reflected. The idea is to have an encrypted value here, hence why I set it as a String.
            What gets encrypted is still open to debate, My idea was to simplify this and just put a number in this field to make counting easier, but once I add an encryption layer, this strategy limits my cipher space quite a lot. But if I concatenate it with a very large random integer tough... Anyway, this needs some thinking, but the idea is to have the frontend setting this field so that the encryption process happens off-chain.
        **/
        access(self) var option: String

        /**
            I need a pair of parameter to prevent an adversary from taking advantage of this system. I need a "voterAddress" as well as a "ballotIndex" parameter that is derived from the initial one. The idea is to use this to ensure that this Ballot is either inside of an account that matches the "voterAddress" parameter, be it by itself or while in a VoteBox, or inside an Election resource. To restrict the Ballot to these two states only, I need to be creative with this aspect.
            For now, I'm setting the ballotIndex as H(voterAddress) = ballotIndex, i.e., the ballotIndex is the hash digest for the address of the voter.
        **/
        access(all) let voterAddress: Address
        access(all) let ballotIndex: String

        // I can put a getter for the Ballot option here as well since there's no danger in returning it, given that its either a default String, or an
        // encrypted option
        access(BallotStandard.BallotAdmin) view fun getOption(): String {
            return self.option
        }


        // The function to set the option parameter. This one is BallotAdmin protected, which is going to require an authorized reference to invoke 
        // this function.
        access(BallotStandard.BallotAdmin) fun vote(newOption: String): Void {
            // There's not a lot more that I need to do. The blinding and encrypting logic needs to necessarily occur outside of this contract.
            self.option = newOption
        }

        access(contract) fun burnCallback(): Void {
            // From the Ballot's point of view, all I need to do is to emit the proper Event
            emit BallotBurned(_ballotId: self.ballotId, _linkedElectionId: self.linkedElectionId)
        }

        init(
            _linkedElectionId: UInt64,
            _electionCapability: Capability,
            _voterAddress: Address
        ) {
            self.ballotId = self.uuid
            self.linkedElectionId = _linkedElectionId
            self.electionCapability = _electionCapability

            // The voterAddress is achieved directly
            self.voterAddress = _voterAddress

            // But the ballotIndex needs more processing. First, cast the voterAddress to a String and then convert that String to a [UInt8]. Finally, 
            // apply the SHA3_256 hashing algorithm to the [UInt8] with the hash digest of the address String.  
            let addressDigest: [UInt8] = HashAlgorithm.SHA3_256.hash(self.voterAddress.toString().utf8)

            // To make things much easier, I'm converting the hash digest, currently set as [UInt8], back to a String to use as a dictionary key.
            self.ballotIndex = String.fromUTF8(addressDigest)!
            // Set any new Ballots to a default option, which for now is just a String saying that. Obviously, this is not a valid option for any election.
            self.option = "default"
        }
    }

    access(all) fun createBallot(newLinkedElectionId: UInt64, newElectionCapability: Capability, newVoterAddress: Address): @BallotStandard.Ballot {
        return <- create Ballot(_linkedElectionId: newLinkedElectionId, _electionCapability: newElectionCapability, _voterAddress: newVoterAddress)
    }

    // Contract constructor
    init() {

    }
}
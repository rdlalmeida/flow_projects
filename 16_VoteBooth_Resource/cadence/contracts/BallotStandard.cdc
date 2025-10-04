/**
    ## The Ballot Token standard

    Interface to regulate the access to the base resource for this project, namely, the Ballot.

    @author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "Burner"

access(all) contract BallotStandard {
// CUSTOM ENTITLEMENTS
    access(all) entitlement BallotAdmin

    // CUSTOM EVENTS
    access(all) event BallotBurned(_ballotId: UInt64, _linkedElectionId:UInt64, _ballotIndex: String)

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
        access(self) let electionCapability: Capability
        
        /**
            This field is used by the Election resource as the key for the internal dictionary where Ballots are stored
            As such, this field needs to be unique and also prevent information leakage to the voter. An obvious choice
            would be the voter's address, since it is a unique element by default, but that raises some privacy issues, since
            there a link somewhere between an address and a Ballot and that's a no no. So, I'm going a level deep and store the
            hash digest of the voter's address in this field and use it as a sort of "private identification string" that is
            also unique, under the assumption that the hash algorithm used is collision resistant to a degree.
            This makes sure that multiple Ballots by the same voter have the same ballotIndex, in principle that is.
        **/
        access(all) let ballotIndex: String

        /**
            This is the field where the choice in the ballot gets reflected. The idea is to have an encrypted value here, hence why I set it as a String.
            What gets encrypted is still open to debate, My idea was to simplify this and just put a number in this field to make counting easier, but once I add an encryption layer, this strategy limits my cipher space quite a lot. But if I concatenate it with a very large random integer tough... Anyway, this needs some thinking, but the idea is to have the frontend setting this field so that the encryption process happens off-chain.
        **/
        access(self) var option: String

        // I can put a getter for the Ballot option here as well since there's no danger in returning it, given that its either a default String, or an
        // encrypted option
        access(self) view fun getOption(): String {
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
            emit BallotBurned(_ballotId: self.ballotId, _linkedElectionId: self.linkedElectionId, _ballotIndex: self.ballotIndex)
        }

        init(
            _linkedElectionId: UInt64,
            _electionCapability: Capability,
            _ballotIndex: String
        ) {
            self.ballotId = self.uuid
            self.linkedElectionId = _linkedElectionId
            self.electionCapability = _electionCapability
            self.ballotIndex = _ballotIndex
            // Set any new Ballots to a default option, which for now is just a String saying that. Obviously, this is not a valid option for any election.
            self.option = "default"
        }
    }
}
/** 
    ## The Ballot Token standard

    This interface regulates the main resource to use in this voting system, namely, the Ballot. This interface allows independent contract to use this resource.

    Ballots are associated to Election resources, which are to be defined in a different contract. Ballots connect to an Election resource through an electionId that uniquely identifies an Election resource.

    Author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "Burner"

access(all) contract interface BallotToken {
    // Entitlements used to regulate the access the option parameter
    access(all) entitlement TallyAdmin
    access(all) entitlement VoteEnable    

    access(all) resource interface Ballot: Burner.Burnable {
        /// The main id to individualize Ballot resources. Use the 'self.uuid' to get a valid and automatic id for this resource
        access(all) let ballotId: UInt64

        /// The main option to represent the choice selected for the current election. This parameter requires a 'VoteEnable' entitlement to be changed
        access(VoteEnable) var option: UInt8?

        /// The id of an Election resource 
        access(all) let electionId: UInt64

        /// The default Ballot option, which also, when selected, identifies a Ballot as a revoke Ballot.
        access(all) let defaultBallotOption: UInt8?

        /// This parameter is set with the address of the contract that mints this Ballot. It is used to retrieve public references from the contract deployer and also to prevent the voting booth contract deployer from voting.
        access(all) let voteBoothDeployer: Address

        /// I've been debating this parameter more than any other. On one end, I want to "lock" a Ballot to a single owner that either cast this Ballot or burns it. The easy approach to this is to keep an internal parameter with this value in the Ballot. But this leads to the other end, where I want this Ballot to remain as anonymous as possible, and keeping a parameter such as the address of the owner in it may invalidate this. But only if someone else is able to access it. I've decided that the small risk and the negligible loss of voter privacy (all one gets accessing this parameter is the voter address and nothing else about him/her) is worth it because not having this parameter is far more riskier than having it (it raises the small probability that someone else rather than the original owner can cast this ballot)
        access(all) var ballotOwner: Address?

        /** 
            The burner callback function, which emits the respective event automatically when a Ballot is burned using the Burner contract
        **/
        access(contract) fun burnCallback(): Void

        /**
            Function to retrieve the name of the Election associated to this Ballot.

            @return: String Returns the name of the election resource to which this Ballot is associated with.
        **/
        access(all) view fun getElectionName(): String


        /**
            Function to retrieve the text of the ballot that should contain both the text of the question posed to the voter, as well as a description of the options available.

            @return: String Returns the ballot text for the election resource associated to this Ballot.
        **/
        access(all) view fun getElectionBallot(): String

        /**
            Function to retrieve the array of options that the voter can chose for the election associated to this Ballot.

            @return: [UInt8] Return the array with options that voters can chose to cast their option in the current Ballot.
        **/
        access(all) view fun getElectionOptions(): [UInt8]

        /**
            Function to retrieve the revoke status of this Ballot, namely, if its set as a revoke Ballot or a "normal" one

            @return: Bool Returns 'true' if the default option is s
        **/
        access(all) view fun isRevoked(): Bool {
            // This one is pretty standard, so it can be defined in this interface
            return (self.option == self.defaultBallotOption)
        }

        /**
            Function to anonymize the Ballot by setting the internal self.ballotOwner parameter to nil.

            NOTE: The only way to set the self.ballotOwner is in the Ballot constructor. This means that, once this ballot is anonymized, it is not possible to recover the original owner. This anonymization should only happen after the Ballot is properly submitted, since there's no going back once this happens.
        **/
        access(all) fun anonymizeBallot(): Void {
            // Remove any information about the Ballot owner by setting this parameter to nil
            self.ballotOwner = nil
        }

        /**
            This function returns the option selected in this Ballot. As expected, this function is protected with a TallyAdmin entitlement so that only users with a Ballot in their storage can access this field. This means that only the voter, as long as it has the Ballot in their storage, and the Tally contract, which is going to store these Ballots in its storage at some point, can access it. Voter privacy preserved, in principle.

            @return: UInt8? Returns the option set in the Ballot, or a nil if the default option is still set (revoke Ballot)
        **/
        access(TallyAdmin) view fun getVote(): UInt8? {
            pre {
                self.owner != nil: "Please use an authorized reference to invoke this function!"
            }

            // The entitlement ensures that only the owner of this Ballot can call this function, so the body of it is actually very simple.
            return self.option
        }

        /**
            Main voting function. It receives an option from the voter, validates it and sets it in the current Ballot.

            @param: newOption (UInt8?) The option to set in this Ballot. Provide a 'nil' to make this Ballot into a revoke one.
        **/
        access(BallotToken.VoteEnable) fun vote(newOption: UInt8?): Void {
            pre {
                self.owner != nil: "Need a valid owner to vote! Please use an authorized reference to this Ballot to vote."
                self.owner!.address != self.voteBoothDeployer: "The election administrator (".concat(self.voteBoothDeployer.toString()).concat(") is not allowed to vote!")
                newOption == self.defaultBallotOption || self.getElectionOptions().contains(newOption!): "The options '".concat(newOption!.toString()).concat("' is not among the valid for this election!")
            }

            // Once the validations are cleared, this function is actually very simple.
            self.option = newOption
        }
    }
}
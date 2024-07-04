/*
*
*   In this example, we want to create a simple approval voting contract where a polling place issues ballots to addresses.
*
*   To run a vote, the Admin deploys the smart contract, then initializes the proposals using the initialize_proposals.cdc transaction.
*   The array of proposals cannot be modified after it has been initialized.
*
*   Then they will give ballots to users by using the issue_ballot.cdc transaction.
*
*   Every iser with a ballot is allowed to approve any number of proposals. A user can choose their votes and cast them with the
*   cast_vote.cdc transaction.
*
*/

pub contract ApprovalVoting {
    // List of proposals to be approved
    pub var proposals: [String]

    // Number of votes per proposal
    pub let votes: {Int: Int}

    // Path to store the administrator resource and other useful ones
    pub let adminStorage: StoragePath
    pub let ballotStorage: StoragePath
    pub let ballotPublic: PublicPath

    /*
        This is the resource that is issued to users. When a user gets a Ballot object, they call the 'vote' function to include their votes,
        and then cast it in the smart contract using the 'cast' function to have their vote included in the polling.
    */
    pub resource Ballot {
        // Array of all proposals
        pub let proposals: [String]

        // Corresponds to an array index in proposals after a vote
        pub var choices: {Int: Bool}

        init() {
            self.proposals = ApprovalVoting.proposals
            self.choices = {}

            // Set each choice to false
            var i: Int = 0

            while (i < self.proposals.length) {
                self.choices[i] = false
                i = i + 1
            }
        }

        // Modifies the ballot to indicate which proposals it is voting for
        pub fun vote(proposal: Int) {
            pre {
                self.proposals[proposal] != nil: "Cannot vote for a proposal that doesn't exist!"
            }

            self.choices[proposal] = true
        }
        
        // Returns the array of proposals for printing purposes
        pub fun getProposals(): [String] {
            return self.proposals
        }
    }

    // Resource that the Administrator of the vote controls to initialize the porposals and to pass out ballot resources to voters
    pub resource Administrator {
        // Function to initialize all the proposals for the voting
        pub fun initializeProposals(_ proposals: [String]) {
            pre {
                /*
                    Here's how to ensure transparency and robustness (elaborate on these later on if possible)
                    This simple pre-condition ensures that the options available in any election are to be set once and only once. One can then
                    publicize the calling of this initialization function (via a transaction) and show how anyone can check the array of proposals
                    created and how it is impossible for it to be changed.
                    This pre-condition ensures that the initialization function can only be called when there are no proposals set yet, i.e.,
                    the condition (ApprovalVoting.proposals.length == 0) evaluates to true, which means that the proposals array is still empty. If
                    there are any proposals already set, i.e., if we are trying to change a voting exercise already in progress, the same condition
                    evaluates to false now, triggers the panic and stops the rest of this function to execute. All of this logic can be freely
                    consulted by anyone because the code that regulates this is openly deployed in a block in the Flow blockchain. No centralized
                    e-voting application ever came close to this level of transaparecy regarding the code that regulates its systems,
                */
                ApprovalVoting.proposals.length == 0: "Proposals can only be initialized once!"
                proposals.length > 0: "Cannot initialize with no proposals!"
            }
            ApprovalVoting.proposals = proposals

            // Set each tally of votes to zero
            var i: Int = 0
            while (i < proposals.length) {
                ApprovalVoting.votes[i] = 0
                i = i + 1
            }
        }

        // The Admin calls this function to create a new Ballot that can be transferred to another user
        pub fun issueBallot(): @Ballot {
            return <- create Ballot()
        }
    }

    /*
        A user moves their ballot to this function in the contract where its votes are tallied and the ballot is destroyed
    */
    pub fun cast(ballot: @Ballot) {
        var index: Int = 0

        // Look through the ballot
        while (index < self.proposals.length) {
            if (ballot.choices[index]!) {
                // Tally the vote if it is approved
                self.votes[index] = self.votes[index]! + 1
            }
            index = index + 1
        }

        // Destroy the ballot because it has been tallied
        destroy ballot
    }

    /*
        Initializes the contract by setting the proposals and votes to empty and creating a new Admin resource to put in storage
    */
    init() {
        self.adminStorage = /storage/VotingAdmin
        self.ballotStorage = /storage/Ballot
        self.ballotPublic = /public/Ballot

        self.proposals = []
        self.votes = {}

        // Before attempting to save the new Administrator, load and destroy anything that can be stored at that location
        let oldAdmin: @AnyResource <- self.account.load<@AnyResource>(from: self.adminStorage)
        
        // Destroy any old resource retrieved
        destroy oldAdmin

        // Now that the storage space is truly empty, save the new Administrator resource into it.
        self.account.save<@Administrator>(<- create Administrator(), to: self.adminStorage)
    }
}
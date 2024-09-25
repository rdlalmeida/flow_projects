/*
    Example of a simple Voting contract, tightly based on the tutorial in https://developers.flow.com/cadence/tutorial/09-voting

    The vote process is regulated by an Admin deployed as smart contract.
    Admin initializes the proposals using a transaction (intitialize_proposals.cdc). The array of proposals becomes fixed after
    being initialized.

    Ballots are given to users, into their accounts, using another transaction (issue_ballot.cdc).

    Users are allowed to approve proposals and can chose their votes and cast them with another transaction (cast_vote.cdc)
*/

pub contract ApprovalVoting {
    // A simple string to denote what the election is all about
    pub let electionTitle: String

    // List of proposals to be approved
    pub var electionContractProposals: [String]

    // Number of votes per proposal
    pub let votes: {String: Int}

    // The storage path to where our Admin resource is going to be stored into
    pub let adminStorage: StoragePath


    // Contract initialization function. This function runs automatically upon contract deployment on the blockchain
    init(electionName: String) {
        // Set the election title
        self.electionTitle = electionName

        // Set the array of proposals to an empty one
        self.electionContractProposals = []

        // Same goes to the vote counting dictionary
        self.votes = {}

        // Set up the storage path for the Administrator Resource too
        self.adminStorage = /storage/adminVoting

        // Create an Admin resource. This can only be done in this stage
        let votingAdmin: @ApprovalVoting.Administrator <- create ApprovalVoting.Administrator()

        // Save the Resource to the contract deployer account's storage
        self.account.save<@Administrator>(<- votingAdmin, to: self.adminStorage)
    }

    /*  
        This is the Ballot resource that is to be used to users.
        When a user gets a Ballot resource, they can call its 'vote' function
        to include their votes, and then cast it in the smart contract using the
        'cast' function. The cast function submits the ballot to be counting into
        the main contract's tally
    */
    pub resource Ballot{
        // Array of all proposals. This array is simply inherited from the proposal array in the main contract
        pub let ballotProposals: [String]

        // And a corresponding dictionary to register which proposals are chosen in this ballot
        pub var choices: {String: Bool}

        // Initialization function. This function is executed automatically every time a new Ballot is created
        init() {
            // Set the array of proposals to the one already set on the main contract
            self.ballotProposals = ApprovalVoting.electionContractProposals
            
            // For now, set the dictionary of choices to an empty one
            self.choices = {}

            // And use a while loop to populate the dictionary
            var i: Int = 0
            while (i < self.ballotProposals.length) {
                /*
                    This instruction does 2 things:
                    1. It creates a new entry in the ApprovalVoting.votes dictionary using the String in proposals[i] as key
                    2. Sets that entry's value to 0, effectively creating something like:
                        ApprovalVoting.votes = {
                            proposals[0]: 0,
                            proposals[1]: 0,
                            ...
                            proposals[10]: 10
                        }
                */
                self.choices[self.ballotProposals[i]] = false
                
                // Don't forget to increment the counter or this function is going to eat up all the transaction's allocated gas!!
                i = i + 1
            }
        }

        // This function modifies the ballot setting the selected option to true, thus indicating which option was selected
        // NOTE: This function does not prevent more than option to be set in this ballot. To prevent double voting we are about to
        // set an additional protection in the vote cast function shortly.
        pub fun vote(proposal: String) {
            pre {
                // Validate the proposal by using an array built in function - contains - to test if the proposal submitted exists. Pre-conditions in
                // these functions need to evaluate to true for the rest of the function to execute. If they evaluate to false, the message is returned
                // instead. The Array.contains(input) function returns true or false depending if the input provided exists in the array or not.
                self.ballotProposals.contains(proposal): "Cannot vote for proposal '".concat(proposal).concat("'. That option is not valid!")
            }

            // If the pre condition was validated, set the selected option to true
            self.choices[proposal] = true
        }
    }

    // And now the Administrator resource that the voted organizer, which has to be the same person controlling the
    // account where this contract is deployed, for security reasons, and it is used to initialize the process by
    // setting up the array of proposals
    pub resource Administrator {
        // Function to initialize all the proposals for the voting
        pub fun initializeProposals(suggestedProposals: [String]) {
            pre{
                ApprovalVoting.electionContractProposals.length == 0: "Proposals can only be initialize once!"
                suggestedProposals.length > 0: "Cannot initialize this election without proposals."
            }

            // Set the contract proposals variable to the array provided as input
            ApprovalVoting.electionContractProposals = suggestedProposals

            // And set every vote count in the counting dictionary to 0 too
            var i: Int = 0

            while (i< suggestedProposals.length) {
                // Same principle as before: create the dictionary entries with the proposal items as keys while setting their corresponding values to 0
                ApprovalVoting.votes[suggestedProposals[i]] = 0

                // Don't forget to increment the counter or this function is going to eat up all the transaction's allocated gas!!
                i = i + 1
            }
        }

        // Call this function to retrieve a Ballot Resource that you can then give to a voter
        pub fun issueBallot(): @ApprovalVoting.Ballot {
            let newBallot: @ApprovalVoting.Ballot <- create ApprovalVoting.Ballot()

            return <- newBallot
        }
    }

    // This function receives a Ballot resource provided by the voter, validates it, tallies the selected option and destroys it in the end
    pub fun cast(ballot: @Ballot): Void {
        // Before counting the option in the ballot, validate it. The validation logic is too complex to set in a pre-condition so it needs a bit more code
        // Begin by extracting all the options, i.e., the values in the Ballot's choices dictionary, into a dedicated array for easier processing
        // Dictionaries in Cadence have built-in functions to retrieve either all the keys or all the values as an array
        let ballotChoices: [Bool] = ballot.choices.values

        // Set a simple counting variable
        var selectedOptions: Int = 0

        // And go through the array of values counting how many 'trues' are there. A valid ballot has only one
        for choice in ballotChoices {
            // If the choice in question is true
            if (choice) {
                // Increment the counting variable by 1
                selectedOptions = selectedOptions + 1
            }
        }

        // Now check if the number of options set to true is one. If its not, panic! This is the Cadence equivalent of raising an Exception, throwing an Error etc.
        // But in this blockchain context, this means that all state changes up to this point are reverted.
        if (selectedOptions == 0) {
            // Panic if the ballot is still empty
            panic("The ballot provided is still empty!")
        }

        if (selectedOptions > 1) {
            // And if the ballot has multiple options set instead of just one.
            // NOTE: These panics do not stop the election. They only prevent invalid ballots from being counted.
            // NOTE 2: The panic function also automatically destroys any "dangling" Resources, namely, the ballot
            panic("The ballot provided has multiple options selected!")
        }

        // If none of the previous conditions were triggered, the ballot is valid. Proceed to count the selected option
        // Begin by extracting all the election options present in the Ballot choices dictionary (keys) to an array for easier processing
        let ballotOptions: [String] = ballot.choices.keys

        // And use a for cycle to check which one of them is true
        for choice in ballotOptions {
            if (ballot.choices[choice]!) {
                // Count the option by incrementing its value by 1
                ApprovalVoting.votes[choice] = ApprovalVoting.votes[choice]! + 1
            }
        }

        // Done. Destroy the resource. This is the digital equivalent of throwing the paper ballot in a shredder
        destroy ballot
    }
}
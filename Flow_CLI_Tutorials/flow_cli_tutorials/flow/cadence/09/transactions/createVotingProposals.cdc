import ApprovalVoting from "../contracts/ApprovalVoting.cdc"

// This transactopm allows the administrator of the Voting contract to create new proposals for voting and save them to the smart contract

transaction() {
    let proposals: [String]
    
    prepare(admin: AuthAccount) {
        self.proposals = ["Longer Shot Clock", "Trampolines instead of hardwood floors", "Ban on soccer balls"]
        // Borrow a reference to the admin Resource
        let adminRef: &ApprovalVoting.Administrator = admin.borrow<&ApprovalVoting.Administrator>(from: ApprovalVoting.adminStorage) ??
            panic("Unable to retrieve an Administrator reference!")

        // Call the initializeProposals function to create the proposals array as an array of strings
        adminRef.initializeProposals(
            self.proposals
        )

        log("Proposals Initialized!")
    }

    post {
        ApprovalVoting.proposals.length == self.proposals.length: 
            "Something went wrong: the number of proposals set in the ApprovalVoting contract does not match the set defined in this transaction!"
    }

    execute {
    }
}
 
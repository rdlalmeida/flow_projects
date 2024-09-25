import ApprovalVoting from "../contracts/ApprovalVoting.cdc"

/*
    This transaction allows the administrator of the Voting contract to create a new ballot and store it in a voter's account
    The voter and the administrator have to both sign the transaction so it can access their storage
*/

transaction() {
    prepare(admin: AuthAccount, voter: AuthAccount) {
        // Borrow a reference to the Admin resource
        let adminRef: &ApprovalVoting.Administrator = admin.borrow<&ApprovalVoting.Administrator>(from: ApprovalVoting.adminStorage) ??
            panic ("Unable to retrieve a valid administrator reference...")

        // Create a new Ballot by calling the issueBallot function to the admin Reference
        let ballot: @ApprovalVoting.Ballot <- adminRef.issueBallot()

        // Store that ballot in the voter's account storage
        voter.save<@ApprovalVoting.Ballot>(<- ballot, to: ApprovalVoting.ballotStorage)

        // Also, create a link to the public storage for verifications purposes (on a PROD application this is highly risky! Do this only
        // for testing purposes)
        voter.link<&ApprovalVoting.Ballot>(ApprovalVoting.ballotPublic, target: ApprovalVoting.ballotStorage)

        log("Ballot transferred to voter!")
    }
}
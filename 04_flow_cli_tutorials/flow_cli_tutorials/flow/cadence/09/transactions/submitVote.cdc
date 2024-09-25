import ApprovalVoting from "../contracts/ApprovalVoting.cdc"

/*
    This transaction allows a voter to select the cotes they would like to make and cast that vote by using the castVote function
    of the ApprovalVoting smart contract
*/
transaction(vote: Int) {

    prepare(voter: AuthAccount) {
        // Start by validating that the vote number provided is equal or lower than the size of the array of proposals stored in the imported
        // contract. Otherwise we are tallying a vote into an inexistent proposal
        pre {
            vote <= ApprovalVoting.proposals.length : 
                "The proposal indicated ('"
                .concat(vote.toString())
                .concat("') does not exist. Please indicate a number between 0 and ")
                .concat((ApprovalVoting.proposals.length - 1).toString())
                .concat(" to continue.")
        }

        // First try to load the ballot from storage and validate it. In this case it is extremely important that we made sure that the object
        // retrieved from storage has the exact same type as expected, to rule out potential fake ballots (need to study the possibility of this
        // hapenning) - Going to use the method that I've developed during the ExampleNFT case

        // Define the type of the resource that is expected to be saved in the storage path. In this case I already know that a valid ballot retrieved
        // from storage must have this specific type
        let expectedReferenceType: Type = Type<@ApprovalVoting.Ballot>()

        // Load whatever is in the storage path to an optional variable
        // NOTE: The 'type' function only works with StoragePath and not with PublicPath. But since everything that is in a PublicPath came from 
        // a StoragePath, just use the Storage one for this purpose
        let storedBallotType: Type? = voter.type(at: ApprovalVoting.ballotStorage)

        // Test if a nil was got instead, which means that nothing was stored at that path in the first place
        if (storedBallotType == nil) {
            // Nothing to do but quit in this case, since there is no ballot saved in storage yet
            panic(
                "The voter with account "
                .concat(voter.address.toString())
                .concat(" does not have a valid Ballot delivered at ")
                .concat(ApprovalVoting.ballotStorage.toString())
                .concat(". Aborting vote...")
            )
        }
        else if (storedBallotType! != expectedReferenceType) {
            // The first if was missed, it means something was set in storage. Check if the type retrieved matches the expected one
            // Note that at this point the resource retrieved from storage is still in its optional format, hence the force cast above
            // In this case, something else other than an expetect ApprovalVoting.Ballot was retrieved instead. Panic this and log
            // the type retrieved instead.
            panic(
                "The voter with account "
                .concat(voter.address.toString())
                .concat(" has a '")
                .concat((storedBallotType!).identifier)
                .concat(" Resource type instead saved in ")
                .concat(ApprovalVoting.ballotStorage.toString())
                .concat(". Unable to proceed...")
            )
        }
        else {
            // The expected case: there'a an ApprovalVoting.Ballot resource in storage and it was properly retrieved
            // Proceed to retrieve the ballot resource and use the vote function on it
            let ballot: @ApprovalVoting.Ballot <- voter.load<@ApprovalVoting.Ballot>(from: ApprovalVoting.ballotStorage)!

            ballot.vote(proposal: vote)

            // Cast the ballot by submitting it to the tallying contract
            ApprovalVoting.cast(ballot: <- ballot)

            // Log the success message
            log("Vote cast and tallied!")
        }
    }
}
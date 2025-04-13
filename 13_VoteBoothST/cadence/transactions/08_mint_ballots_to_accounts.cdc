import "VoteBoothST"
import "NonFungibleToken"

/*
    This function is an adaptation of the previous transaction but adapted to process a bunch of accounts at once rather than one at a time as the previous one
    This transaction requires an array of valid voter addresses to which a new Ballot is to be transferred to.
    If the transaction fails to deposit the ballot at some point, it does not panic nor reverts: the offending address and ballot id are set in a 'BallotNotDelivered' event and emitted
*/

transaction(voteBoxAccounts: [Address]) {
    let ballotPrinterRef: auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin
    var voteBoxRefs: [&VoteBoothST.VoteBox]
    var recipientAddresses: [Address]

    prepare(signer: auth(Storage) &Account) {
        // Initiate the arrays
        self.voteBoxRefs = []
        self.recipientAddresses = []

        // Prepare the base references
        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.BallotPrinterAdmin at "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )

        // Populate the arrays with any valid reference to VoteBoxes found
        for voteBoxAccount in voteBoxAccounts {
            // Try to catch a temporary reference and validate it
            let tempAccount: &Account = getAccount(voteBoxAccount)

            let tempVoteBoxRef: &VoteBoothST.VoteBox = tempAccount.capabilities.borrow<&VoteBoothST.VoteBox>(VoteBoothST.voteBoxPublicPath) ??
            panic(
                "Unable to retrieve a valid &VoteBoothST.VoteBox at "
                .concat(VoteBoothST.voteBoxPublicPath.toString())
                .concat(" for account ")
                .concat(voteBoxAccount.toString())
            )

            self.voteBoxRefs.append(tempVoteBoxRef)
            self.recipientAddresses.append(voteBoxAccount)
        }
    }

    execute {
        // Done. Mint the Ballots and deliver those to the VoteBoxes

        for index, recipientAddress in self.recipientAddresses {
            let newBallot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: recipientAddress)

            let newBallotId: UInt64 = newBallot.id

            self.voteBoxRefs[index].depositBallot(ballot: <- newBallot)

            if (VoteBoothST.printLogs) {
                log(
                    "Successfully minted a Ballot with id "
                    .concat(newBallotId.toString())
                    .concat(" into the VoteBoothST.VoteBox at ")
                    .concat(VoteBoothST.voteBoxPublicPath.toString())
                    .concat(" for account ")
                    .concat(recipientAddress.toString())
                )
            }
        }

    }
}
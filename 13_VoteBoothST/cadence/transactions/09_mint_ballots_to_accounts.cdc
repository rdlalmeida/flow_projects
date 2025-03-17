import "VoteBoothST"
import "NonFungibleToken"

/*
    This function is an adaptation of the previous transaction but adapted to process a bunch of accounts at once rather than one at a time as the previous one
    This transaction requires an array of valid voter addresses to which a new Ballot is to be transferred to.
    If the transaction fails to deposit the ballot at some point, it does not panic nor reverts: the offending address and ballot id are set in a 'BallotNotDelivered' event and emitted
*/

transaction(voteBoxAccounts: [Address]) {
    let ballotPrinterRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin
    var voteBoxRefs: [&{NonFungibleToken.Receiver}]
    var recipientAddresses: [Address]

    prepare(signer: auth(Storage) &Account) {
        // Initiate the arrays
        self.voteBoxRefs = []
        self.recipientAddresses = []

        // Prepare the base references
        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
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

            let tempReference: &{NonFungibleToken.Receiver}? = tempAccount.capabilities.borrow<&{NonFungibleToken.Collection}>(VoteBoothST.voteBoxPublicPath)

            // If the previous operation failed, emit the proper event and continue
            if (tempReference == nil) {
                // Unable to obtain a valid reference (reason 1). Emit the respective event
                VoteBoothST.emitBallotNotDelivered(voterAddress: voteBoxAccount, reason: 1)

                // Nothing more to do with this one. Continue to the next address. Log a simple message for testing purposes
                log(
                    "Unable to retrieve a valid &VoteBoothST.VoteBox at "
                    .concat(VoteBoothST.voteBoxPublicPath.toString())
                    .concat(" for account ")
                    .concat(voteBoxAccount.toString())
                )
                continue
            }
            else {
                // The reference is valid. Check if the VoteBox collection is empty or not
                let voteBoxRef: &VoteBoothST.VoteBox = tempReference as! &VoteBoothST.VoteBox

                if (voteBoxRef.getLength() > 0) {
                    // The VoteBox in question is full (reason 2). Emit the event and continue
                    VoteBoothST.emitBallotNotDelivered(voterAddress: voteBoxAccount, reason: 2)

                    log(
                        "The VoteBoothST.VoteBox retrieved at "
                        .concat(VoteBoothST.voteBoxPublicPath.toString())
                        .concat(" for account ")
                        .concat(voteBoxAccount.toString())
                        .concat(" is full! Cannot deposit any more ballots!")
                    )

                    continue
                }
                else {
                    // All validations OK. Put the valid reference in the reference array and add the address to the valid users array
                    self.voteBoxRefs.append(voteBoxRef)
                    self.recipientAddresses.append(voteBoxAccount)

                }
            }
        }
    }

    execute {
        // Done. Mint the Ballots and deliver those to the VoteBoxes

        for index, recipientAddress in self.recipientAddresses {
            let newBallot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: recipientAddress)

            let newBallotId: UInt64 = newBallot.id

            self.voteBoxRefs[index].deposit(token: <- newBallot)

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
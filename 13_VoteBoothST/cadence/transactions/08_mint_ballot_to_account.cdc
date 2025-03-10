import "VoteBoothST"
import "NonFungibleToken"

transaction(recipient: Address) {
    let ballotPrinterRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin
    let voteBoxRef: &{NonFungibleToken.Receiver}
    let recipientAddress: Address
    let ownerControlRef: &VoteBoothST.OwnerControl

    prepare(signer: auth(Storage, Capabilities) &Account) {
        let recipientAccount: &Account = getAccount(recipient)

        let voteBoxExists: Bool = recipientAccount.capabilities.exists(VoteBoothST.voteBoxPublicPath)

        if (!voteBoxExists) {
            panic(
                "ERROR: Unable to retrieve a valid Capability<&VoteBoothST.VoteBox> from account "
                .concat(recipient.toString())
                .concat(" stored in public path at ")
                .concat(VoteBoothST.voteBoxPublicPath.toString())
            )
        }

        self.voteBoxRef = recipientAccount.capabilities.borrow<&{NonFungibleToken.Collection}>(VoteBoothST.voteBoxPublicPath) ??
        panic(
            "Account "
            .concat(recipient.toString())
            .concat(" does not have a NonFungibleToken.Collection Receiver at ")
            .concat(VoteBoothST.voteBoxPublicPath.toString())
            .concat(". The account must initialize their account with this collection first!")
        )

        self.recipientAddress = recipient

        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "The signer does not store a VoteBoothST.BallotPrinterAdmin object at the path "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(". The signer must initialize their account with this collection first.")
        )

        self.ownerControlRef = signer.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.OwnerControl at "
            .concat(VoteBoothST.ownerControlPublicPath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )
    }

    execute {
        let testBallot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: self.recipientAddress)

        let testBallotId: UInt64 = testBallot.id
        let testBallotOwner: Address = testBallot.ballotOwner

        // Check that the records added to the internal structures of the OwnerControl resource are consistent
        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.ballotOwners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while the OwnerControl.owners has ")
                .concat(self.ownerControlRef.getBallotCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }

        var storedBallotId: UInt64? = self.ownerControlRef.getBallotId(owner: testBallotOwner)
        var storedBallotOwner: Address? = self.ownerControlRef.getBallotOwner(ballotId: testBallotId)

        if (storedBallotOwner == nil) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with id "
                .concat(testBallotId.toString())
                .concat(" does not have a valid owner in the OwnerControl dictionary!")
            )
        }
        else if (storedBallotOwner! != testBallotOwner) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with id "
                .concat(testBallotId.toString())
                .concat(" should have owner ")
                .concat(testBallotOwner.toString())
                .concat(" but got this owner instead: ")
                .concat(storedBallotOwner!.toString())
            )
        }
        
        if (storedBallotId == nil) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with owner "
                .concat(testBallotOwner.toString())
                .concat(" has a nil ballotId in the OwnerControl dictionary!")
            )
        }
        else if (storedBallotId! != testBallotId) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with owner "
                .concat(testBallotOwner.toString())
                .concat(" should have Id ")
                .concat(testBallotId.toString())
                .concat(" but got this Id instead: ")
                .concat(storedBallotId!.toString())
            )
        }

        self.voteBoxRef.deposit(token: <- testBallot)

        log(
            "Successfully minted a Ballot with id "
            .concat(testBallotId.toString())
            .concat(testBallotId.toString())
            .concat(" into the VoteBoothST.VoteBox at ")
            .concat(VoteBoothST.voteBoxPublicPath.toString())
            .concat(" for account ")
            .concat(self.recipientAddress.toString())
        )
    }
}
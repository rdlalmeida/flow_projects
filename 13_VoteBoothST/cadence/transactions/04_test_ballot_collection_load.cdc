import "VoteBoothST"

/*
    This transaction is very similar to the one named "01_test_ballot_printer_admin.cdc", namely, it tries to load the ballot collection resource from storage and, if successful, try to print a ballot into the Collection, withdraw it and burn it to finish the test. If all is OK, only the contract deployer should be able to run this transaction successfully. Any other users should not be able to create BallotBoxes, therefore they should not be able to access them as well. The same logic applies to the BallotPrinterAdmin
*/
transaction(testAddress: Address) {
    let ballotPrinterRef: auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin
    let ownerControlRef: &VoteBoothST.OwnerControl

    prepare(signer: auth(Storage, VoteBoothST.BoothAdmin) &Account) {
        let storedBallotBox: @VoteBoothST.BallotBox <- signer.storage.load<@VoteBoothST.BallotBox>(from: VoteBoothST.ballotBoxStoragePath) ??
        panic(
            "Unable to retrieve a valid VoteBoothST.BallotBox resource from path "
            .concat(VoteBoothST.ballotBoxStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        let collectionSize: Int = storedBallotBox.getSubmittedBallotCount()

        if (VoteBoothST.printLogs) {
            // Test that this collection is still empty
            log(
                "Ballot Collection retrieved from account "
                .concat(signer.address.toString())
                .concat(" currently contains ")
                .concat(collectionSize.toString())
                .concat(" Ballots in it")
            )
        }

        // There's a "saySomething" function in it, as usual. Test it too
        log("Testing the Collection's 'saySomething' function: ")
        log(storedBallotBox.saySomething())

        // Load the BallotPrinterAdmin resource reference 
        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.BallotPrinterAdmin at "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        // Print a test ballot under a test address because the contract deployer is forbidden from minting Ballots
        let testBallot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: testAddress)
        let testBallotId: UInt64 = testBallot.id
        let testBallotOwner: Address = testBallot.ballotOwner

        // Check the OwnerControl structure to make sure everything is OK so far
        self.ownerControlRef = signer.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.OwnerControl at "
            .concat(VoteBoothST.ownerControlPublicPath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )

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

        var storedBallotId: UInt64? = self.ownerControlRef.getBallotId(owner: testBallotOwner)

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

        // Finally, check the consistency function as well
        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.ballotOwners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while the OwnerControl.owners has ")
                .concat(self.ownerControlRef.getBallotCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }

        // All is OK. Deposit the ballot into the BallotBox
        storedBallotBox.submitBallot(ballot: <- testBallot)

        // Check the size of the BallotBox again
        let newBallotBoxSize: Int = storedBallotBox.getSubmittedBallotCount()

        // Check that the function that verifies if the ballotOwner has a valid submitted Ballot returns true
        var ballotSubmitted: Bool = storedBallotBox.getIfOwnerVoted(ballotOwner: testBallotOwner)

        if (!ballotSubmitted) {
            // If I got a false in this one
            panic(
                "ERROR: Ballot owner "
                .concat(testBallotOwner.toString())
                .concat(" does not have a valid Ballot submitted yet!")
            )
        }

        // Conversely, there should be no Ballots submitted by the contract deployer. Test this as well
        ballotSubmitted = storedBallotBox.getIfOwnerVoted(ballotOwner: signer.address)

        if (ballotSubmitted) {
            // If there's a Ballot submitted under this contract deployer's address, that's clearly an error as well!
            panic(
                "ERROR: The VotingBoothST contract deployer "
                .concat(signer.address.toString())
                .concat(" has a valid Ballot submitted!")
            )
        }

        if (VoteBoothST.printLogs) {
            log(
                "Deposited Ballot with ID "
                .concat(testBallotId.toString())
                .concat(" to a Ballot Collection for account ")
                .concat(testBallotOwner.toString())
            )
        }

        // Validate that the size of the collection was adjusted accordingly
        if (newBallotBoxSize != collectionSize + 1) {
            panic(
                "Collection size mismatch detected: Initial collection size: "
                .concat(collectionSize.toString())
                .concat(" Ballots. After depositing one ballot, the collection size is now ")
                .concat(newBallotBoxSize.toString())
                .concat(" Ballots!")
            )
        }

        // All good. Withdraw the ballot again

        let depositedBallot: @VoteBoothST.Ballot <- storedBallotBox.withdrawBallot(ballotOwner: testBallotOwner)
        let depositedBallotId: UInt64 = depositedBallot.id

        // Check also that the before and after Ballot ids match
        if(testBallotId != depositedBallotId) {
            panic(
                "ERROR: The Ballot id changed! Before deposit, the Ballot had id "
                .concat(testBallotId.toString())
                .concat(". After withdraw from account ")
                .concat(signer.address.toString())
                .concat(", the Ballot has now id ")
                .concat(depositedBallotId.toString())
            )
        }

        // Done. Burn it
        self.ballotPrinterRef.burnBallot(ballotToBurn: <-depositedBallot)

        // Check the consistency of the OwnerControl structure
        storedBallotOwner = self.ownerControlRef.getBallotOwner(ballotId: testBallotId)

        if (storedBallotOwner != nil) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with id "
                .concat(testBallotId.toString())
                .concat(" should not have any records in the OwnerControl dictionary (nil), but it still got owner ")
                .concat(storedBallotOwner!.toString())
            )
        }

        storedBallotId = self.ownerControlRef.getBallotId(owner: testBallotOwner)

        if (storedBallotId != nil) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with owner "
                .concat(testBallotOwner.toString())
                .concat(" should not have any records in the OwnerControl dictionary (nil), but it still got Id ")
                .concat(storedBallotId!.toString())
            )
        }

        // Do one final verification of the OwnerControl structures
        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.owners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while the OwnerControl.owners has ")
                .concat(self.ownerControlRef.getBallotCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }

        if (VoteBoothST.printLogs) {
            log(
                "Successfully withdrawn and burned ballot #"
                .concat(depositedBallotId.toString())
                .concat(" from account ")
                .concat(signer.address.toString())
            )
        }

        // Done. Send the Resource back to storage
        signer.storage.save<@VoteBoothST.BallotBox>(<- storedBallotBox, to: VoteBoothST.ballotBoxStoragePath)
    }

    execute {

    }
}
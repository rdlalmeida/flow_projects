import "VoteBoothST"

/*
    This transaction is very similar to the one named "01_test_ballot_printer_admin.cdc", namely, it tries to load the ballot collection resource from storage and, if successful, try to print a ballot into the Collection, withdraw it and burn it to finish the test. If all is OK, only the contract deployer should be able to run this transaction successfully. Any other users should not be able to create BallotCollections, therefore they should not be able to access them as well. The same logic applies to the BallotPrinterAdmin
*/
transaction() {
    let ballotPrinterRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin

    prepare(signer: auth(Storage) &Account) {
        let storedBallotCollection: @VoteBoothST.BallotCollection <- signer.storage.load<@VoteBoothST.BallotCollection>(from: VoteBoothST.ballotCollectionStoragePath) ??
        panic(
            "Unable to retrieve a valid VoteBoothST.BallotCollection resource from path "
            .concat(VoteBoothST.ballotCollectionStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        let collectionSize: Int = storedBallotCollection.getLength()

        // Test that this collection is still empty
        log(
            "Ballot Collection retrieved from account "
            .concat(signer.address.toString())
            .concat(" currently contains ")
            .concat(collectionSize.toString())
            .concat(" Ballots in it")
        )

        // There's a "saySomething" function in it, as usual. Test it too
        log("Testing the Collection's 'saySomething' function: ")
        log(storedBallotCollection.saySomething())

        // Load the BallotPrinterAdmin resource reference 
        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.BallotPrinterAdmin at "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        // Print a test ballot under the deployer's address
        let testBallot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: signer.address)
        let testBallotId: UInt64 = testBallot.id

        // Deposit the ballot into the BallotCollection
        storedBallotCollection.deposit(token: <- testBallot)

        log(
            "Deposited Ballot with ID "
            .concat(testBallotId.toString())
            .concat(" to a Ballot Collection for account ")
            .concat(signer.address.toString())
        )

        // Validate that the size of the collection was adjusted accordingly
        if (storedBallotCollection.getLength() != collectionSize + 1) {
            panic(
                "Collection size mismatch detected: Initial collection size: "
                .concat(collectionSize.toString())
                .concat(" Ballots. After depositing one ballot, the collection size is now ")
                .concat(storedBallotCollection.getLength().toString())
                .concat(" Ballots!")
            )
        }

        // All good. Withdraw the ballot again

        let depositedBallot: @VoteBoothST.Ballot <- storedBallotCollection.withdraw(withdrawID: testBallotId) as! @VoteBoothST.Ballot
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

        log(
            "Successfully withdrawn and burned ballot #"
            .concat(depositedBallotId.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )

        // Done. Send the Resource back to storage
        signer.storage.save<@VoteBoothST.BallotCollection>(<- storedBallotCollection, to: VoteBoothST.ballotCollectionStoragePath)
    }

    execute {

    }
}
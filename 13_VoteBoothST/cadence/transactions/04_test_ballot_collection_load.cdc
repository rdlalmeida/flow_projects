import "VoteBoothST"

/*
    This transaction is very similar to the one named "01_test_ballot_printer_admin.cdc", namely, it tries to load the ballot collection resource from storage and, if successful, send it back to storage
    No events are expected to be emitted
*/
transaction() {
    prepare(signer: auth(Storage) &Account) {
        let storedBallotCollection: @VoteBoothST.BallotCollection <- signer.storage.load<@VoteBoothST.BallotCollection>(from: VoteBoothST.ballotCollectionStoragePath) ??
        panic(
            "Unable to retrieve a valid VoteBoothST.BallotCollection resource from path "
            .concat(VoteBoothST.ballotCollectionStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        // Test that this collection is still empty
        log(
            "Ballot Collection retrieved from account "
            .concat(signer.address.toString())
            .concat(" currently contains ")
            .concat(storedBallotCollection.ownedNFTs.length.toString())
            .concat(" Ballots in it")
        )

        // There's a "saySomething" function in it, as usual. Test it too
        log("Testing the Collection's 'saySomething' function: ")
        log(storedBallotCollection.saySomething())

        // Done. Send the Resource back to storage
        signer.storage.save<@VoteBoothST.BallotCollection>(<- storedBallotCollection, to: VoteBoothST.ballotCollectionStoragePath)
    }

    execute {

    }
}
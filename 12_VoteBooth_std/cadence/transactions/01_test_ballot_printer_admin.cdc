import "VoteBooth_std"

/* 
    This transaction is solely used to test if the BallotPrinterAdmin resource was properly created and it is in the right place and, more importantly, it only allows the deployer account to use it.
    As such, this transaction loads the BallotPrinterAdmin resource, prints a BallotNFT, destroys it and loads the BallotPrinterAdmin back into storage before finishing.

    Events that should be emitted in this transaction:
    1. VoteBooth_std.BallotMinted
    2. VoteBooth_std.BallotBurned
    3. NonFungibleToken.NFT.ResourceDestroyed

    Events that should NOT be emitted in this transaction:
    1. VoteBooth_std.ContractDataInconsistent
*/

transaction() {
    prepare(signer: auth(Storage) &Account) {
        let storedBallotPrinterAdmin: @VoteBooth_std.BallotPrinterAdmin <- signer.storage.load<@VoteBooth_std.BallotPrinterAdmin>(from: VoteBooth_std.ballotPrinterAdminStoragePath) ?? 
        panic(
            "Unable to retrieve a valid VoteBooth_std.BallotPrinterAdmin resource from storage from account "
            .concat(signer.address.toString())
        )

        // Use the printer to get a Ballot
        let newBallot: @VoteBooth_std.Ballot <- storedBallotPrinterAdmin.printBallot(voterAddress: signer.address)

        // Nothing else to do. Destroy the ballot
        storedBallotPrinterAdmin.burnBallot(ballotToBurn: <- newBallot)
        

        // Done. Send the printer back into storage
        signer.storage.save<@VoteBooth_std.BallotPrinterAdmin>(<- storedBallotPrinterAdmin, to:VoteBooth_std.ballotPrinterAdminStoragePath)
    }

    execute {

    }
}
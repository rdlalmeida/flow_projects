import "VoteBoothST"


transaction() {
    prepare(signer: auth(Storage) &Account) {
        let storedBallotPrinterAdmin: @VoteBoothST.BallotPrinterAdmin <- signer.storage.load<@VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid VoteBoothST.BallotPrinterAdmin resource from storage from account "
            .concat(signer.address.toString())
        )

        let newBallot: @VoteBoothST.Ballot <- storedBallotPrinterAdmin.printBallot(voterAddress: signer.address)

        storedBallotPrinterAdmin.burnBallot(ballotToBurn: <- newBallot)

        signer.storage.save<@VoteBoothST.BallotPrinterAdmin>(<- storedBallotPrinterAdmin, to: VoteBoothST.ballotPrinterAdminStoragePath)
    }

    execute {

    }
}
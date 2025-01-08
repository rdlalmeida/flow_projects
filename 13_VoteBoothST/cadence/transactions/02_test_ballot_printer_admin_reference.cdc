import "VoteBoothST"

transaction() {
    let printerReference: &VoteBoothST.BallotPrinterAdmin
    let ownerAddress: Address

    prepare(signer: auth(Capabilities) &Account) {
        self.ownerAddress = signer.address

        self.printerReference = signer.capabilities.borrow<&VoteBoothST.BallotPrinterAdmin>(VoteBoothST.ballotPrinterAdminPublicPath) ??
        panic(
            "Unable to get a &VoteBoothST.BallotPrinterAdmin from account "
            .concat(signer.address.toString())
        )
    }

    execute {
        let newBallot: @VoteBoothST.Ballot <- self.printerReference.printBallot(voterAddress: self.ownerAddress)

        log(
            "Got a valid ballot with id "
            .concat(newBallot.id.toString())
            .concat(" for address ")
            .concat(newBallot.ballotOwner.toString())
        )

        self.printerReference.burnBallot(ballotToBurn: <- newBallot)
    }
}
import "VoteBooth_std"

transaction() {

    let printerReference: &VoteBooth_std.BallotPrinterAdmin
    let ownerAddress: Address
    
    prepare(signer: auth(Capabilities) &Account) {
        self.ownerAddress = signer.address

        self.printerReference = signer.capabilities.borrow<&VoteBooth_std.BallotPrinterAdmin>(VoteBooth_std.ballotPrinterAdminPublicPath) ?? panic(
            "Unable to get a &VoteBooth_std.BallotPrinterAdmin from account "
            .concat(signer.address.toString())
        )
    }

    execute{
        // Let's try to mint and burn a Ballot token as well
        let newBallot: @VoteBooth_std.Ballot <- self.printerReference.printBallot(voterAddress: self.ownerAddress)

        log(
            "Got a valid ballot with id "
            .concat(newBallot.id.toString())
            .concat(" for address ")
            .concat(newBallot.ballotOwner.toString())
        )

        self.printerReference.burnBallot(ballotToBurn: <- newBallot)
    }
}
import "VoteBoothST"

transaction() {
    let printerReference: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin
    let ownerAddress: Address

    prepare(signer: auth(Capabilities, Storage) &Account) {
        self.ownerAddress = signer.address

        self.printerReference = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to get a &VoteBoothST.BallotPrinterAdmin from path "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        // self.printerReference = signer.capabilities.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(VoteBoothST.ballotPrinterAdminPublicPath) ??
        // panic(
        //     "Unable to get a &VoteBoothST.BallotPrinterAdmin from path "
        //     .concat(VoteBoothST.ballotPrinterAdminPublicPath.toString())
        //     .concat(" for account ")
        //     .concat(signer.address.toString())
        // )
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
import "VoteBoothST"

transaction(newVoter: Address) {
    let printerReference: auth(VoteBoothST.Admin, Insert) &VoteBoothST.BallotPrinterAdmin
    let ownerAddress: Address

    prepare(signer: auth(Capabilities, Storage, VoteBoothST.Admin, Insert) &Account) {
        self.ownerAddress = signer.address

        self.printerReference = signer.storage.borrow<auth(VoteBoothST.Admin, Insert) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to get a &VoteBoothST.BallotPrinterAdmin from path "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )
    }

    execute {
        let newBallot: @VoteBoothST.Ballot <- self.printerReference.printBallot(voterAddress: newVoter)

        log(
            "Got a valid ballot with id "
            .concat(newBallot.id.toString())
            .concat(" for address ")
            .concat(newBallot.ballotOwner.toString())
        )

        self.printerReference.burnBallot(ballotToBurn: <- newBallot)
    }
}
import "VoteBoothST"

transaction(newVoter: Address) {
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
    }

    execute {
        let newBallot: @VoteBoothST.Ballot <- self.printerReference.printBallot(voterAddress: newVoter)

        let ballotId: UInt64 = newBallot.id
        let ballotOwner: Address = newBallot.ballotOwner

        if (VoteBoothST.printLogs) {
            log(
                "Got a valid ballot with id "
                .concat(ballotId.toString())
                .concat(" for address ")
                .concat(ballotOwner.toString())
            )
        }

        self.printerReference.burnBallot(ballotToBurn: <- newBallot)

        if (VoteBoothST.printLogs) {
            log(
                "Successfully burned Ballot #"
                .concat(ballotId.toString())
                .concat(" from owner ")
                .concat(ballotOwner.toString())
            )
        }
    }
}
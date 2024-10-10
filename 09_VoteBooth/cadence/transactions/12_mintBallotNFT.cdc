import "VoteBooth_std"

transaction(ballotRecipient: Address) {
    // let ballotPrinterCapability: Capability<&VoteBooth_std.BallotPrinterAdmin>
    let ballotPrinterRef: &VoteBooth_std.BallotPrinterAdmin
    let voteBoxRef: &VoteBooth_std.VoteBox

    prepare(signer: auth(BorrowValue) &Account) {
        /*
            NOTE to my future self. This:

                self.ballotPrinterRef = signer.storage.borrow<&VoteBooth_std.BallotPrinterAdmin>(from: VoteBooth_std.ballotPrinterAdminStoragePath) ?? 
                panic("Unable to borrow a BallotPrinterAdmin reference from account ".concat(signer.address.toString()))

            does not work when I sign the transaction with the same account that deployed the contract. That is a good sign since I was not expecting this to work in the first place. If it did, what the hell are capabilities used for anyways?
        */
        
        // Grab references to both the ballot printer and the voter's VoteBox. Panic otherwise, since there's little to do if no minter is available
        // self.ballotPrinterCapability = signer.capabilities.get<&VoteBooth_std.BallotPrinterAdmin>(VoteBooth_std.ballotPrinterAdminPublicPath)

        // self.ballotPrinterRef = self.ballotPrinterCapability.borrow() ??
        // panic("Unable to borrow a BallotPrinterAdmin reference from account ".concat(signer.address.toString()))

        self.ballotPrinterRef = signer.storage.borrow<&VoteBooth_std.BallotPrinterAdmin>(from: VoteBooth_std.ballotPrinterAdminStoragePath) ?? 
        panic(
            "Unable to borrow a BallotPrinterAdmin reference from account "
            .concat(signer.address.toString())
            .concat(" from path ")
            .concat(VoteBooth_std.ballotPrinterAdminStoragePath.toString())
        )

        // Grab a public reference for the recipient's account
        let recipientAccount: &Account = getAccount(ballotRecipient)

        // And use it to get a reference to a VoteBox in his/her account. Panic if this does not exist yet
        self.voteBoxRef = recipientAccount.capabilities.borrow<&VoteBooth_std.VoteBox>(VoteBooth_std.voteBoxPublicPath) ??
        panic("Unable to borrow a reference to a VoteBox for account ".concat(ballotRecipient.toString()))
    }

    execute {
        // Done. Let's try to do this then
        let ballot: @VoteBooth_std.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: ballotRecipient)

        // Put the ballot in the voter's box
        self.voteBoxRef.deposit(token: <- ballot)

    }
}
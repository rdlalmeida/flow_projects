import "VoteBoothST"
import "NonFungibleToken"

transaction(recipient: Address) {
    let ballotPrinterRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin
    let voteBoxRef: &{NonFungibleToken.Receiver}
    let recipientAddress: Address

    prepare(signer: auth(Storage, Capabilities) &Account) {
        let recipientAccount: &Account = getAccount(recipient)

        let voteBoxExists: Bool = recipientAccount.capabilities.exists(VoteBoothST.voteBoxPublicPath)

        if (!voteBoxExists) {
            panic(
                "ERROR: Unable to retrieve a valid Capability<&VoteBoothST.VoteBox> from account "
                .concat(recipient.toString())
                .concat(" stored in public path at ")
                .concat(VoteBoothST.voteBoxPublicPath.toString())
            )
        }

        self.voteBoxRef = recipientAccount.capabilities.borrow<&{NonFungibleToken.Collection}>(VoteBoothST.voteBoxPublicPath) ??
        panic(
            "Account "
            .concat(recipient.toString())
            .concat(" does not have a NonFungibleToken.Collection Receiver at ")
            .concat(VoteBoothST.voteBoxPublicPath.toString())
            .concat(". The account must initialize their account with this collection first!")
        )

        self.recipientAddress = recipient

        // TODO: Test if borrowing this reference from the public capability instead changes anything in this process
        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "The signer does not store a VoteBoothST.BallotPrinterAdmin object at the path "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(". The signer must initialize their account with this collection first.")
        )
    }

    execute {
        let newBallot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: self.recipientAddress)

        let ballotId: UInt64 = newBallot.id

        self.voteBoxRef.deposit(token: <- newBallot)

        log(
            "Successfully minted a Ballot with id "
            .concat(ballotId.toString())
            .concat(" into the VoteBoothST.VoteBox at ")
            .concat(VoteBoothST.voteBoxPublicPath.toString())
            .concat(" for account ")
            .concat(self.recipientAddress.toString())
        )
    }
}
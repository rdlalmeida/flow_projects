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

        /*
            NOTE: To print a new Ballot, I need an authorized reference requested by the contract deployer. This limits the printing of new Ballots to a single address, i.e., the one that deployed the contract in the first place.

            Cadence only allows authorized references to be retrievable through the "<account>.storage.borrow<auth (...)>" API element. It is possible to publish a "normal" capability into the public domain and then retrieve it through the "<account>.capabilities.borrow<...>" API element, but any authorized elements from the original resource, i.e., parameters and functions with a "access(<ENTITLEMENT>)" modifier, are not available, only the ones with an "access(all)" modifier.
        */
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
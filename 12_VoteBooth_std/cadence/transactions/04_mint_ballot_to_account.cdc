import "VoteBooth_std"
import "NonFungibleToken"

transaction(recipient: Address) {
    let minterRef: &VoteBooth_std.BallotPrinterAdmin
    let voteBoxRef: &{NonFungibleToken.Receiver}
    let recipientAddress: Address
    prepare(signer: auth(Capabilities) &Account) {
        let recipientAccount: &Account = getAccount(recipient)

        let voteBoxExists: Bool = recipientAccount.capabilities.exists(VoteBooth_std.voteBoxPublicPath)

        // If the VoteBox capability does not exist, there's nothing else this transaction can do because it cannot get access to the recipient's storage. Panic if that it is the case
        if (!voteBoxExists) {
            panic(
                "ERROR: Unable to retrieve a valid Capability<&VoteBooth_std.VoteBox> from account "
                .concat(recipient.toString())
                .concat(" stored in public path at ")
                .concat(VoteBooth_std.voteBoxPublicPath.toString())
            )
        }

        // All good. Continue by getting a valid reference for the recipient's VoteBox
        self.voteBoxRef = recipientAccount.capabilities.borrow<&{NonFungibleToken.Receiver}>(VoteBooth_std.voteBoxPublicPath) ?? 
        panic(
            "Unable to retrieve a valid reference to a &VoteBooth_std.VoteBox at "
            .concat(VoteBooth_std.voteBoxPublicPath.toString())
            .concat(" for account ")
            .concat(recipient.toString())
        )

        // Get the minter reference also
        self.minterRef = signer.capabilities.borrow<&VoteBooth_std.BallotPrinterAdmin>(VoteBooth_std.ballotPrinterAdminPublicPath) ??
        panic(
            "Unable to retrieve a valid reference to a &VoteBooth_std.BallotPrinterAdmin at "
            .concat(VoteBooth_std.ballotPrinterAdminPublicPath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        // Store the recipient address for the execute phase
        self.recipientAddress = recipient
    }

    execute{
        // All good. Mint and deposit the NFT
        let newBallot: @VoteBooth_std.Ballot <- self.minterRef.printBallot(voterAddress: self.recipientAddress)

        let newBallotId: UInt64 = newBallot.id

        self.voteBoxRef.deposit(token: <- newBallot)

        // Sent out a simple log just for informative reasons
        log(
            "Successfully minted a new Ballot with id "
            .concat(newBallotId.toString())
            .concat(" into a VoteBox to account ")
            .concat(self.recipientAddress.toString())
        )
    }
}
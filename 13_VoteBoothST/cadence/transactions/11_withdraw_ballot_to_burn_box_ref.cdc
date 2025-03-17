import "VoteBoothST"
import "NonFungibleToken"

// This transaction tests the deposit/withdraw mechanics for a referenced VoteBox. It expects a Ballot in the user's VoteBox and deposits it to the contract deployer's BurnBox for future processing

transaction(deployerAddress: Address) {
    let voteBoxRef: auth(NonFungibleToken.Withdraw) &VoteBoothST.VoteBox
    let burnBoxRef: &VoteBoothST.BurnBox
    let signerAddress: Address

    prepare(signer: auth(Storage) &Account) {
        // Grab the reference for the BurnBox in the contract deployer account
        let deployerAccount: &Account = getAccount(deployerAddress)
        self.burnBoxRef = deployerAccount.capabilities.borrow<&VoteBoothST.BurnBox>(VoteBoothST.burnBoxPublicPath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.BurnBox at "
            .concat(VoteBoothST.burnBoxPublicPath.toString())
            .concat(" for account ")
            .concat(deployerAddress.toString())
        )

        self.voteBoxRef = signer.storage.borrow<auth(NonFungibleToken.Withdraw) &VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )

        self.signerAddress = signer.address
    }

    execute {
        let ballotIDs: [UInt64] = self.voteBoxRef.getIDs()

        if (ballotIDs.length == 0) {
            panic(
                "VoteBox retrieved from account "
                .concat(self.signerAddress.toString())
                .concat(" has 0 Ballots!")
            )
        }
        else if (ballotIDs.length > 1) {
            panic(
                "VoteBox retrieved from account "
                .concat(self.signerAddress.toString())
                .concat(" has ")
                .concat(ballotIDs.length.toString())
                .concat(" ballots in it! Only one Ballot is allowed per VoteBox!")
            )
        }

        let ballot: @VoteBoothST.Ballot <- self.voteBoxRef.withdraw(withdrawID: ballotIDs[ballotIDs.length - 1]) as! @VoteBoothST.Ballot

        let ballotToBurnId: UInt64 = ballot.id
        let ballotToBurnOwner: Address = ballot.ballotOwner

        // Use the burnBoxRef to set this ballot to be burned, at some point
        self.burnBoxRef.depositBallotToBurn(ballotToBurn: <- ballot)

        if (VoteBoothST.printLogs) {
            log(
                "Successfully withdraw and set Ballot #"
                .concat(ballotToBurnId.toString())
                .concat(" from owner ")
                .concat(ballotToBurnOwner.toString())
                .concat(" from a VoteBox in account ")
                .concat(self.signerAddress.toString())
            )
        }
    }
}
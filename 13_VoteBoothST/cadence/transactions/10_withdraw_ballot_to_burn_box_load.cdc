import "VoteBoothST"
import "NonFungibleToken"

// This transaction tests the deposit/withdraw mechanics for a loaded VoteBox. It expects a Ballot in the user's VoteBox and deposits it to the deployer's BurnBox for future processing

transaction(deployerAddress: Address) {
    let burnBoxRef: &VoteBoothST.BurnBox

    prepare(signer: auth(Storage) &Account) {
        // Get the public reference for the BurnBox
        let deployerAccount: &Account = getAccount(deployerAddress)

        self.burnBoxRef = deployerAccount.capabilities.borrow<&VoteBoothST.BurnBox>(VoteBoothST.burnBoxPublicPath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.BurnBox at "
            .concat(VoteBoothST.burnBoxPublicPath.toString())
            .concat(" for account ")
            .concat(deployerAddress.toString())
        )

        let voteBox: @VoteBoothST.VoteBox <- signer.storage.load<@VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to retrieve a @VoteBootST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        let ballotIDs: [UInt64] = voteBox.getIDs()

        if (ballotIDs.length == 0) {
            panic(
                "VoteBox retrieved from account "
                .concat(signer.address.toString())
                .concat(" has 0 Ballots!")
            )
        }
        else if (ballotIDs.length > 1) {
            panic(
                "VoteBox retrieved from account "
                .concat(signer.address.toString())
                .concat(" has ")
                .concat(ballotIDs.length.toString())
                .concat(" ballots in it! Only one Ballot is allowed per VoteBox!")
            )
        }

        let ballot: @VoteBoothST.Ballot <- voteBox.withdraw(withdrawID: ballotIDs[ballotIDs.length - 1]) as! @VoteBoothST.Ballot

        let ballotToBurnId: UInt64 = ballot.id
        let ballotToBurnOwner: Address = ballot.ballotOwner

        // Use the burnBoxRef to set this ballot to be burned, at some point
        self.burnBoxRef.depositBallotToBurn(ballotToBurn: <- ballot)

        signer.storage.save<@VoteBoothST.VoteBox>(<- voteBox, to: VoteBoothST.voteBoxStoragePath)

        log(
            "Successfully withdraw and set Ballot #"
            .concat(ballotToBurnId.toString())
            .concat(" from owner ")
            .concat(ballotToBurnOwner.toString())
            .concat(" from a VoteBox in account ")
            .concat(signer.address.toString())
        )
    }

    execute {

    }
}
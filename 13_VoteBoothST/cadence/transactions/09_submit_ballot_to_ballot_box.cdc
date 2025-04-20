import "VoteBoothST"
import "NonFungibleToken"

/*
    This transaction casts a vote, i.e., it sets the provided option as argument to a Ballot that should be present in the VoteBox associated to the transaction signer. This script can be used to submit a valid vote, a revoke vote (option = 0) and an invalid vote for testing purposes.
*/

transaction(voteOption: UInt8) {
    let voteBoxRef: auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox
    let signerAddress: Address
    let ballotBoxRef: &VoteBoothST.BallotBox
    let ownerControlRef: &VoteBoothST.OwnerControl
    let deployerAddress: Address?

    prepare(signer: auth(Storage) &Account) {
        self.voteBoxRef = signer.storage.borrow<auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )

        // Once I have a reference for a valid VoteBox, check that it has a Ballot already. Panic if not because there's no point in continuing without a Ballot already in the box
        // The VoteBox function that returns the VoteBoothDeployer returns a nil if no Ballots are in storage yet, or return the desired address if its not the case. Use it to validate the ballot existence and get the deployer account
        self.deployerAddress = self.voteBoxRef.getVoteBoothDeployer()

        if (self.deployerAddress == nil) {
            panic(
                "The VoteBox retrieved from account "
                .concat(signer.address.toString())
                .concat(" has no Ballots yet! Cannot continue!")
            )
        }

        // All good. Get the deployer account from the address retrieved
        let deployerAccount: &Account = getAccount(self.deployerAddress!)

        self.ballotBoxRef = deployerAccount.capabilities.borrow<&VoteBoothST.BallotBox>(VoteBoothST.ballotBoxPublicPath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.BallotBox at "
            .concat(VoteBoothST.ballotBoxPublicPath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        self.signerAddress = signer.address

        self.ownerControlRef = deployerAccount.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
        panic(
            "Unable to get a valid &VoteBoothST.OwnerControl at "
            .concat(VoteBoothST.ownerControlPublicPath.toString())
            .concat(" from account ")
            .concat(self.deployerAddress!.toString())
        )
    }

    execute {
        // Before submitting the Ballot, there should be a couple of concurrent entries in the OwnerControl resource. I can check if they are consistent without having an authorised reference.
        // Use the signer address to retrieve a ballotId from the OwnerControl
        let storedBallotId: UInt64? = self.ownerControlRef.getBallotId(owner: self.signerAddress)

        if (storedBallotId == nil) {
            panic(
                "ERROR: No Ballots found in the OwnerControl for owner "
                .concat(self.signerAddress.toString())
            )
        }

        // Check the consistency of the internal dictionaries by getting the owner using the ballotId
        let storedOwner: Address? = self.ownerControlRef.getOwner(ballotId: storedBallotId!)

        if (storedOwner == nil) {
            panic(
                "ERROR: No valid owner found for ballotId "
                .concat(storedBallotId!.toString())
            )
        }
        else if(storedOwner! != self.signerAddress) {
            panic(
                "ERROR: The OwnerControl returned owner "
                .concat(storedOwner!.toString())
                .concat(" but the signer has address ")
                .concat(self.signerAddress.toString())
            )
        }

        // Check that the OwnerControl is still consistent
        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: The OwnerControl for account "
                .concat(self.deployerAddress!.toString())
                .concat(" is not consistent!")
            )
        }

        // Use the VoteBox to cast a vote with option 1
        self.voteBoxRef.castVote(option: voteOption)

        // Submit this Ballot. It's a valid one so it should be stored nicely in the BallotBox
        self.voteBoxRef.submitBallot()
        
        if (self.voteBoxRef.hasBallot()) {
            // While the VoteBox should have none
            panic(
                "ERROR: The VoteBox from account "
                .concat(self.signerAddress.toString())
                .concat(" still has a Ballot in the account!")
            )
        }

        // Finally, check the OwnerControl for the same consistencies as before. In this case, I should have a nil for the previous entries
        let newStoredBallotId: UInt64? = self.ownerControlRef.getBallotId(owner: storedOwner!)

        if (newStoredBallotId != nil) {
            panic(
                "ERROR: OwnerControl for account "
                .concat(self.deployerAddress!.toString())
                .concat(" still has ballotId associated to owner ")
                .concat(storedOwner!.toString())
            )
        }

        let newStoredOwner: Address? = self.ownerControlRef.getOwner(ballotId: storedBallotId!)

        if (newStoredOwner != nil) {
            panic(
                "ERROR: OwnerControl for account "
                .concat(self.deployerAddress!.toString())
                .concat(" still has owner ")
                .concat(newStoredOwner!.toString())
                .concat(" associated to ballotId ")
                .concat(storedBallotId!.toString())
            )
        }

        // Terminate with a validation of OwnerControl consistency
        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: OwnerControl for account "
                .concat(self.deployerAddress!.toString())
                .concat(" is not consistent anymore!")
            )
        }
    }
}
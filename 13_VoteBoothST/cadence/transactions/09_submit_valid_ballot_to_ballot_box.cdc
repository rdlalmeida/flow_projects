import "VoteBoothST"
import "NonFungibleToken"

/*
    This transaction changes the option of a previously minted and deposited ballot and submits it to a BallotBox. Because it is a valid Ballot, it should be deposited properly.
*/

transaction(deployerAddress: Address) {
    let voteBoxRef: auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox
    let signerAddress: Address
    let ballotBoxRef: &VoteBoothST.BallotBox
    let ownerControlRef: &VoteBoothST.OwnerControl

    prepare(signer: auth(Storage) &Account) {
        // Grab the reference for the BurnBox in the contract deployer account
        let deployerAccount: &Account = getAccount(deployerAddress)

        self.voteBoxRef = signer.storage.borrow<auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )

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
            .concat(deployerAddress.toString())
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
                .concat(deployerAddress.toString())
                .concat(" is not consistent!")
            )
        }

        if (!self.voteBoxRef.hasBallot()) {
            panic(
                "VoteBox retrieved from account "
                .concat(self.signerAddress.toString())
                .concat(" has 0 Ballots!")
            )
        }

        // Use the VoteBox to cast a vote with option 1
        self.voteBoxRef.castVote(option: 1)

        // Submit this Ballot. It's a valid one so it should be stored nicely in the BallotBox
        self.voteBoxRef.submitBallot()

        // Check that the BallotBox has one submitted ballot
        let submittedBallots: Int = self.ballotBoxRef.getSubmittedBallotCount()

        if (submittedBallots != 1) {
            // The BallotBox should have only one Ballot
            panic(
                "ERROR: The Ballot Box from account "
                .concat(deployerAddress.toString())
                .concat(" has ")
                .concat(submittedBallots.toString())
                .concat(". Expected only 1")
            )
        }
        else if (self.voteBoxRef.hasBallot()) {
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
                .concat(deployerAddress.toString())
                .concat(" still has ballotId associated to owner ")
                .concat(storedOwner!.toString())
            )
        }

        let newStoredOwner: Address? = self.ownerControlRef.getOwner(ballotId: storedBallotId!)

        if (newStoredOwner != nil) {
            panic(
                "ERROR: OwnerControl for account "
                .concat(deployerAddress.toString())
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
                .concat(deployerAddress.toString())
                .concat(" is not consistent anymore!")
            )
        }
    }
}
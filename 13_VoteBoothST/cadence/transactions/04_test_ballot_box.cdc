import "VoteBoothST"
import "NonFungibleToken"

transaction(testAddress: Address) {
    let ballotBoxRef: auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotBox
    let ballotPrinterRef: auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin
    let signerAddress: Address
    let ownerControlRef: &VoteBoothST.OwnerControl

    prepare(signer: auth(Capabilities, Storage, VoteBoothST.BoothAdmin) &Account) {
        self.ballotBoxRef = signer.storage.borrow<auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotBox>(from: VoteBoothST.ballotBoxStoragePath) ??
        panic(
            "Unable to retrieve a valid auth(VoteBoothST.BoothAdmin) &ValidBoothST.BallotBox reference from "
            .concat(VoteBoothST.ballotBoxStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        self.signerAddress = signer.address

        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin at "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" from account ")
            .concat(self.signerAddress.toString())
        )

        self.ownerControlRef = signer.capabilities.borrow<&VoteBoothST.OwnerControl>(VoteBoothST.ownerControlPublicPath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.OwnerControl at "
            .concat(VoteBoothST.ownerControlPublicPath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )
    }

    execute {
        let currentBallotBoxSize: Int = self.ballotBoxRef.getSubmittedBallotCount()

        if (VoteBoothST.printLogs) {
            log(
                "BallotBox reference retrieved from account "
                .concat(VoteBoothST.ballotBoxPublicPath.toString())
                .concat(" currently contains ")
                .concat(currentBallotBoxSize.toString())
                .concat(" Ballots in it ")
            )
        }

        log("Testing the BallotBox's 'saySomething' function: ")
        log(self.ballotBoxRef.saySomething())

        let testBallot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: testAddress)

        let testBallotId: UInt64 = testBallot.id
        let testBallotOwner: Address = testBallot.ballotOwner

        // Validate the consistency of the OwnerControl structure
        var storedBallotOwner: Address? = self.ownerControlRef.getOwner(ballotId: testBallotId)

        if (storedBallotOwner == nil) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with id "
                .concat(testBallotId.toString())
                .concat(" does not have a valid owner in the OwnerControl dictionary!")
            )
        }
        else if (storedBallotOwner! != testBallotOwner) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with id "
                .concat(testBallotId.toString())
                .concat(" should have owner ")
                .concat(testBallotOwner.toString())
                .concat(" but got this owner instead: ")
                .concat(storedBallotOwner!.toString())
            )
        }

        var storedBallotId: UInt64? = self.ownerControlRef.getBallotId(owner: testBallotOwner)

        if (storedBallotId == nil) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with owner "
                .concat(testBallotOwner.toString())
                .concat(" has a nil ballotId in the OwnerControl dictionary!")
            )
        }
        else if (storedBallotId! != testBallotId) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with owner "
                .concat(testBallotOwner.toString())
                .concat(" should have Id ")
                .concat(testBallotId.toString())
                .concat(" but got this Id instead: ")
                .concat(storedBallotId!.toString())
            )
        }

        // Finish with the consistency check function as usual
        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.ballotOwners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while the OwnerControl.owners has ")
                .concat(self.ownerControlRef.getBallotIdsCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }

        // Deposit the ballot into the collection. This ballot has only the default option set because I'm unable to vote at this point. Voting can only happen through an authorized reference to a VoteBox in an account storage other than the contract deployer. As such, this ballot is going to be marked as a revoke Ballot and burned upon submission
        self.ballotBoxRef.submitBallot(ballot: <- testBallot)

        // The ballotSubmitted flag should be false 
        var ballotSubmitted: Bool = self.ballotBoxRef.getIfOwnerVoted(ballotOwner: testBallotOwner)

        if (ballotSubmitted) {
            // If I got a true in this one
            panic(
                "ERROR: Ballot with owner "
                .concat(testBallotOwner.toString())
                .concat(" was successfully submitted when it should have been revoked instead!")
            )
        }

        // There should be no Ballots submitted by the contract deployer. Test this as well
        ballotSubmitted = self.ballotBoxRef.getIfOwnerVoted(ballotOwner: self.signerAddress)

        if (ballotSubmitted) {
            // If there's a Ballot submitted under this contract deployer's address, that's clearly an error as well!
            panic(
                "ERROR: The VotingBoothST contract deployer "
                .concat(self.signerAddress.toString())
                .concat(" has a valid Ballot submitted!")
            )
        }

        let newBallotBoxSize: Int = self.ballotBoxRef.getSubmittedBallotCount()

        // The BallotBox size should remain unchanged
        if (currentBallotBoxSize != newBallotBoxSize) {
            panic(
                "Collection size mismatch detected: Initial collection size: "
                .concat(currentBallotBoxSize.toString())
                .concat(" Ballots. After depositing one ballot, the collection size is now ")
                .concat(newBallotBoxSize.toString())
                .concat(" Ballots!")
            )
        }

        // Finish this by checking the consistency of the OwnerControl structure once again
        storedBallotOwner = self.ownerControlRef.getOwner(ballotId: testBallotId)

        if (storedBallotOwner != nil) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with id "
                .concat(testBallotId.toString())
                .concat(" should not have any records in the OwnerControl dictionary (nil), but it still got owner ")
                .concat(storedBallotOwner!.toString())
            )
        }

        storedBallotId = self.ownerControlRef.getBallotId(owner: testBallotOwner)

        if (storedBallotId != nil) {
            panic(
                "ERROR: Contract Data inconsistency detected: Ballot with owner "
                .concat(testBallotOwner.toString())
                .concat(" should not have any records in the OwnerControl dictionary (nil), but it still got Id ")
                .concat(storedBallotId!.toString())
            )
        }

        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.owners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while the OwnerControl.owners has ")
                .concat(self.ownerControlRef.getBallotIdsCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }
    }
}
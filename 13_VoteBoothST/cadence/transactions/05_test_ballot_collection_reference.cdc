import "VoteBoothST"
import "NonFungibleToken"

transaction(testAddress: Address) {
    let BallotBoxRef: auth(NonFungibleToken.Withdraw) &VoteBoothST.BallotBox
    let ballotPrinterRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin
    let signerAddress: Address
    let ownerControlRef: &VoteBoothST.OwnerControl

    prepare(signer: auth(Capabilities, Storage, VoteBoothST.Admin) &Account) {
        self.BallotBoxRef = signer.storage.borrow<auth(NonFungibleToken.Withdraw) &VoteBoothST.BallotBox>(from: VoteBoothST.ballotBoxStoragePath) ??
        panic(
            "Unable to retrieve a valid &ValidBoothST.BallotBox reference from "
            .concat(VoteBoothST.ballotBoxStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        self.signerAddress = signer.address

        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.BallotPrinterAdmin at "
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
        log(
            "Ballot Collection reference retrieved from account "
            .concat(VoteBoothST.ballotBoxPublicPath.toString())
            .concat(" currently contains ")
            .concat(self.BallotBoxRef.ownedNFTs.length.toString())
            .concat(" Ballots in it ")
        )

        log("Testing the Collection's 'saySomething' function: ")
        log(self.BallotBoxRef.saySomething())

        let testBallot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: testAddress)

        let testBallotId: UInt64 = testBallot.id
        let testBallotOwner: Address = testBallot.ballotOwner

        let currentCollectionSize: Int = self.BallotBoxRef.getLength()

        // Validate the consistency of the OwnerControl structure
        var storedBallotOwner: Address? = self.ownerControlRef.getBallotOwner(ballotId: testBallotId)

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
                .concat(self.ownerControlRef.getBallotCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }

        // Deposit the ballot into the collection
        self.BallotBoxRef.deposit(token: <- testBallot)

        let newCollectionSize: Int = self.BallotBoxRef.getLength()

        if (currentCollectionSize + 1 != newCollectionSize) {
            panic(
                "Collection size mismatch detected: Initial collection size: "
                .concat(currentCollectionSize.toString())
                .concat(" Ballots. After depositing one ballot, the collection size is now ")
                .concat(newCollectionSize.toString())
                .concat(" Ballots!")
            )
        }

        let depositedBallot: @VoteBoothST.Ballot <- self.BallotBoxRef.withdraw(withdrawID: testBallotId) as! @VoteBoothST.Ballot

        let depositedBallotId: UInt64 = depositedBallot.id

        if (testBallotId != depositedBallotId) {
            panic(
                "ERROR: The Ballot id changed! Before deposit, the Ballot had id "
                .concat(testBallotId.toString())
                .concat(". After withdraw from account ")
                .concat(self.signerAddress.toString())
                .concat(", the Ballot has now id ")
                .concat(depositedBallotId.toString())
            )
        }

        // Done with this one. Burn the ballot
        self.ballotPrinterRef.burnBallot(ballotToBurn: <-depositedBallot)

        // Finish this by checking the consistency of the OwnerControl structure once again
        storedBallotOwner = self.ownerControlRef.getBallotOwner(ballotId: testBallotId)

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
                .concat(self.ownerControlRef.getBallotCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }

        log(
            "Successfully withdrawn and burned ballot #"
            .concat(depositedBallotId.toString())
            .concat(" from account ")
            .concat(self.signerAddress.toString())
        )
    }
}
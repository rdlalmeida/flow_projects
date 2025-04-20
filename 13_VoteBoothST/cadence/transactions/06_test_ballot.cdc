import "VoteBoothST"
import "NonFungibleToken"
import "Burner"

transaction(testAddress: Address) {
    let ballotPrinterRef: auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin
    let signerAddress: Address
    let ownerControlRef: &VoteBoothST.OwnerControl

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.signerAddress = signer.address

        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.BoothAdmin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.ballotPrinterAdmin at "
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
        // Try and mint a ballot for testing purposes
        let ballot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: testAddress)

        // Test the consistency of the OwnerControl structure, but use the functions for that and count the number of entries in both internal
        // dictionaries. Previous tests have been more thorough in that aspect
        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.ballotOwners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while the OwnerControl.owners has ")
                .concat(self.ownerControlRef.getBallotIdsCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }

        // Take note of the length of one of the internal dictionaries (doesn't matter which one) so that I can compare that, after burning this test Ballot, these decrease by one
        let initialOwnerControlSize: Int = self.ownerControlRef.getBallotIdsCount()

        // Use this opportunity to test a bunch of Ballot only functions
        let views: [Type] = ballot.getViews()

        if (views != []) {
            panic(
                "ERROR: Ballot.getViews() has returned the wrong parameter!"
            )
        }

        let resolvedViews: AnyStruct? = ballot.resolveView(Type<@VoteBoothST.Ballot>())

        if (resolvedViews != nil) {
            panic(
                "ERROR: Ballot.resolveViews() has returned the wrong parameter!"
            )
        }

        let something: String? = ballot.saySomething()
        let expectedMessage: String = "Hello from the VoteBoothST.Ballot Resource!"

        if (something == nil) {
            panic(
                "ERROR: Ballot.saySomething() has failed: a nil was retuned!"
            )
        }
        else if (something != expectedMessage) {
            panic(
                "ERROR: Ballot.saySomething() has failed: Expected '"
                .concat(expectedMessage)
                .concat("', got '")
                .concat(something!)
            )
        }

        let emptyDummyCollection: @{NonFungibleToken.Collection} <- ballot.createEmptyCollection()

        if (VoteBoothST.printLogs) {
            log(
                "Got a DummyCollection with type: "
                .concat(emptyDummyCollection.getType().identifier)
            )
        }
        
        // Check that the Collection was created empty
        if(emptyDummyCollection.getLength() != 0) {
            panic(
                "ERROR: The DummyCollection created is not empty! It was created with "
                .concat(emptyDummyCollection.getLength().toString())
                .concat(" elements in it! It should be empty!")
            )
        }

        // Done. Destroy the DummyCollection
        destroy emptyDummyCollection

        // Time to test the function that return the election parameters
        let contractElectionName: String = VoteBoothST.getElectionName()
        let ballotElectionName: String = ballot.getElectionName()

        if (contractElectionName != ballotElectionName) {
            panic(
                "ERROR: Contract Election Name: '"
                .concat(contractElectionName)
                .concat("', Ballot Election Name: '")
                .concat(ballotElectionName)
                .concat("'. These values need to match!")
            )
        }

        let contractElectionSymbol: String = VoteBoothST.getElectionSymbol()
        let ballotElectionSymbol: String = ballot.getElectionSymbol()

        if (contractElectionSymbol != ballotElectionSymbol) {
            panic(
                "ERROR: Contract Election Symbol: '"
                .concat(contractElectionSymbol)
                .concat("', Ballot Election Symbol: '")
                .concat(ballotElectionSymbol)
                .concat("'. These values need to match!")
            )
        }

        let contractElectionBallot: String = VoteBoothST.getElectionBallot()
        let ballotElectionBallot: String = ballot.getElectionBallot()

        if (contractElectionBallot != ballotElectionBallot) {
            panic(
                "ERROR: Contract Election Ballot: '"
                .concat(contractElectionBallot)
                .concat("', Ballot Election Ballot: '")
                .concat(ballotElectionBallot)
                .concat("'. These values need to match!")
            )
        }

        let contractElectionLocation: String = VoteBoothST.getElectionLocation()
        let ballotElectionLocation: String = ballot.getElectionLocation()

        if (contractElectionLocation != ballotElectionLocation) {
            panic(
                "ERROR: Contract Election Location: '"
                .concat(contractElectionLocation)
                .concat("', Ballot Election Location: '")
                .concat(ballotElectionLocation)
                .concat("'. These values need to match!")
            )
        }

        let contractElectionOptions: [UInt8] = VoteBoothST.getElectionOptions()
        let ballotElectionOptions: [UInt8] = ballot.getElectionOptions()

        if (contractElectionOptions != ballotElectionOptions) {
            panic(
                "ERROR: Contract Election Options do not match the ones returned from the ballot!"
            )
        }

        let testBallotId: UInt64 = ballot.id
        let testBallotOwner: Address = ballot.ballotOwner

        // Burn the test Ballot using the function from the ballotPrinterAdminRef so that the OwnerControl dictionaries keep their consistency. This is because I've set this function to remove the entries from the internal dictionaries from the OwnerControl before actually destroying the resource. Otherwise I'm going to provoke a ContractDataInconsistency
        self.ballotPrinterRef.burnBallot(ballotToBurn: <- ballot)

        let currentOwnerControlSize: Int = self.ownerControlRef.getBallotIdsCount()

        // Check the consistency as usual before exiting
        if (!self.ownerControlRef.isConsistent()) {
            // This one only checks if both internal dictionaries have the same number of entries. I also need to check if the length of the dictionaries were decrease by 1 and only 1 entry.
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.ballotOwners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while the OwnerControl.owners has ")
                .concat(self.ownerControlRef.getBallotIdsCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }
        // If all went well, my currentOwnerControlSize is going to be one less than my initialOwnerControlSize to account with the correct removal of one record from each of the internal dictionaries. Test that as well
        else if(initialOwnerControlSize != currentOwnerControlSize + 1) {
            panic(
                "ERROR: Contract Data Inconsistency detected! The OwnerControl internal dictionaries failed to reduce their entries by 1 after the burning the Ballot!"
            )
        }

        if (VoteBoothST.printLogs) {
            log(
                "Successfully withdrawn and burned ballot #"
                .concat(testBallotId.toString())
                .concat(" from ballot owner ")
                .concat(testBallotOwner.toString())
            )
        }
    }
}
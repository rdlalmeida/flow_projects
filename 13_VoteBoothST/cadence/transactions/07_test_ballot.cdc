import "VoteBoothST"
import "NonFungibleToken"

transaction(testAddress: Address) {
    let ballotPrinterRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin
    let signerAddress: Address
    let ownerControlRef: &VoteBoothST.OwnerControl

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.signerAddress = signer.address

        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
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
                .concat(self.ownerControlRef.getBallotCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }

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

        let emptyVoteBox: @{NonFungibleToken.Collection} <- ballot.createEmptyCollection()

        log(
            "Got a VoteBox with type: "
            .concat(emptyVoteBox.getType().identifier)
        )
        
        // Check that the Collection was created empty
        if(emptyVoteBox.getLength() != 0) {
            panic(
                "ERROR: The VoteBox created is not empty! It was created with "
                .concat(emptyVoteBox.getLength().toString())
                .concat(" elements in it! It should be empty!")
            )
        }

        // Done. Destroy the emptyVoteBox
        destroy emptyVoteBox

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

        let contractElectionOptions: [UInt64] = VoteBoothST.getElectionOptions()
        let ballotElectionOptions: [UInt64] = ballot.getElectionOptions()

        if (contractElectionOptions != ballotElectionOptions) {
            panic(
                "ERROR: Contract Election Options do not match the ones returned from the ballot!"
            )
        }

        let testBallotId: UInt64 = ballot.id
        let testBallotOwner: Address = ballot.ballotOwner

        destroy ballot

        // Check the consistency as usual before exiting
        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.ballotOwners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while the OwnerControl.owners has ")
                .concat(self.ownerControlRef.getBallotCount().toString())
                .concat(" entries! These should have the same length!")
            )
        }

        log(
            "Successfully withdrawn and burned ballot #"
            .concat(testBallotId.toString())
            .concat(" from ballot owner ")
            .concat(testBallotOwner.toString())
        )
    }
}
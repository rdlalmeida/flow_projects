import "VoteBoothST"
import "NonFungibleToken"

transaction() {
    let ballotPrinterRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin
    let signerAddress: Address

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.signerAddress = signer.address

        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.ballotPrinterAdmin at "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" from account ")
            .concat(self.signerAddress.toString())
        )
    }

    execute {
        // Try and mint a ballot for testing purposes
        let ballot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: self.signerAddress)

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

        // TODO: Continue from here. The transaction fails when it tries to create the emptyVoteBox resource because of a 'isSupportedTypes' blunder. Run the transaction again in the emulator to get the error back
        // let emptyVoteBox: @{NonFungibleToken.Collection} <- ballot.createEmptyCollection()

        // // Test if the type matches
        // if (emptyVoteBox.getType() != Type<@{NonFungibleToken.Collection}>()) {
        //     panic(
        //         "ERROR: The emptyVoteBox returned has type '"
        //         .concat(emptyVoteBox.getType().identifier)
        //         .concat("'. Expected: @{NonFungibleToken.Collection}")
        //     )
        // }
        
        // // Check that the Collection was created empty
        // if(emptyVoteBox.getLength() != 0) {
        //     panic(
        //         "ERROR: The VoteBox created is not empty! It was created with "
        //         .concat(emptyVoteBox.getLength().toString())
        //         .concat(" elements in it! It should be empty!")
        //     )
        // }

        // // Done. Destroy the emptyVoteBox
        // destroy emptyVoteBox

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

        // Use the ballot to test stuff before destroying it
        destroy ballot
    }
}
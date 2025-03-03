// NOTE: This stupid, stupid transaction crashes by no apparent reason when run in the normal emulator. But, if run as a test, it works fine! Go figure... The Flow dudes need to fix the CLI

import "VoteBoothST"

transaction(someAddress: Address) {
    let ownerControlRef: auth(VoteBoothST.Admin) &VoteBoothST.OwnerControl
    let ownerAddress: Address
    let testAddress: Address

    prepare(signer: auth(Storage, Capabilities, VoteBoothST.Admin) &Account) {
        self.ownerAddress = signer.address
        self.testAddress = someAddress
        // Test the OwnerControl resource by pulling an authorized reference and running some functions of it
        self.ownerControlRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.OwnerControl>(from: VoteBoothST.ownerControlStoragePath)
        ??
        panic(
            "Unable to retrieve a valid auth(VoteBoothST.Admin) &VoteBoothST.OwnerControl at "
            .concat(VoteBoothST.ownerControlStoragePath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )
    }

    execute {
        /*
            Use the OwnerControl reference to check that both the ballotOwner and owners internal dictionaries were created empty. Safe to say that this function should only be called right after the contract is deployed. After that, the expectation is that these structures are going to be filled
        */
        let ballotOwners: {UInt64: Address} = self.ownerControlRef.getBallotOwners()
        
        if (ballotOwners != {}) {
            panic(
                "ERROR: The OwnerControl resource at "
                .concat(VoteBoothST.ownerControlStoragePath.toString())
                .concat(" has a non-empty ballotOwners dictionary in it!")
            )
        }

        let owners: {Address: UInt64} = self.ownerControlRef.getOwners()

        if (owners != {}) {
            panic(
                "ERROR: The OwnerControl resource at "
                .concat(VoteBoothST.ownerControlStoragePath.toString())
                .concat(" has a non-empty owners dictionary in it!")
            )
        }

        // If all went OK, log a simple message acknowledging it
        log(
            "The OwnerControl resource at "
            .concat(VoteBoothST.ownerControlStoragePath.toString())
            .concat(" for account ")
            .concat(self.ownerAddress.toString())
            .concat(" is consistent. ballotOwners and owners are still empty.")
        )

        // Insert a bogus record using the dedicated function and test if it was OK
        let testId: UInt64 = 1234

        /*
            The goal with this transaction is to test every line of the OwnerControl resource, which includes a couple of data inconsistency lines that need to be triggered. I'm purposely adding the same data twice to try and trigger these
        */

        self.ownerControlRef.setBallotOwner(ballotId: testId, ballotOwner: self.testAddress)
        // The next execution does the same exact thing as above, but it should trigger an event emission
        self.ownerControlRef.setBallotOwner(ballotId: testId, ballotOwner: self.testAddress)

        self.ownerControlRef.setOwner(ballotOwner: self.testAddress, ballotId: testId)
        self.ownerControlRef.setOwner(ballotOwner: self.testAddress, ballotId: testId)

        // Get the internal structures back and check that there are OK
        var newBallotOwners: {UInt64: Address} = self.ownerControlRef.getBallotOwners()
        var newOwners: {Address: UInt64} = self.ownerControlRef.getOwners()

        // Grab the new parameters using the dedicated functions as well
        let newBallotOwner: Address? = self.ownerControlRef.getBallotOwner(ballotId: testId)
        let newBallotId: UInt64? = self.ownerControlRef.getBallotId(owner: self.testAddress)

        if (newBallotOwners.length != 1) {
            panic(
                "ERROR: The ballotOwners dictionary has the wrong size! Expected size: 1, Current size: "
                .concat(newBallotOwners.length.toString())
            )
        }

        let newStoredOwner: Address? = newBallotOwners[testId]

        if (newStoredOwner == nil) {
            panic(
                "ERROR: Unable to get a valid owner for ballotOwners["
                .concat(testId.toString())
                .concat("]. Got a nil instead.")
            )
        }
        else if (newStoredOwner! != self.testAddress) {
            panic(
                "ERROR: The ballotOwners dictionary was wrongly constructed. For ballotOwners["
                .concat(testId.toString())
                .concat("] expected value = ")
                .concat(self.testAddress.toString())
                .concat(", but got ")
                .concat(newStoredOwner!.toString())
            )
        }
        else if (newBallotOwner == nil) {
            panic(
                "ERROR: The getBallotOwner function returned a nil owner!"
            )
        }
        else if (newBallotOwner! != newStoredOwner!) {
            panic(
                "ERROR: The owner returned from getBallotOwner ("
                .concat(newBallotOwner!.toString())
                .concat(") does not match the one retrieved directly from ballotOwners (")
                .concat(newStoredOwner!.toString())
                .concat(").")
            )
        }
        else {
            log(
                "Added a new record to the ballotOwners structure: ballotOwners["
                .concat(testId.toString())
                .concat("] = ")
                .concat(newStoredOwner!.toString())
            )
        }

        if (newOwners.length != 1) {
            panic(
                "ERROR: The owners dictionary has the wrong size!. Expected size: 1, Current size: "
                .concat(newOwners.length.toString())
            )
        }

        let newStoredId: UInt64? = newOwners[self.testAddress]

        if (newStoredId == nil) {
            panic(
                "ERROR: Unable to get a valid ballotId for owners["
                .concat(self.testAddress.toString())
                .concat("]. Got a nil instead.")
            )
        }
        else if (newStoredId! != testId) {
            panic(
                "ERROR: The owners dictionary was wrongly constructed. For owners["
                .concat(self.testAddress.toString())
                .concat("] expected value = ")
                .concat(testId.toString())
                .concat(", but got ")
                .concat(newStoredId!.toString())
            )
        }
        else if (newBallotId == nil) {
            panic(
                "ERROR: The getBallotId function returned a nil!"
            )
        }
        else if (newBallotId! != newStoredId!) {
            panic(
                "ERROR: The ballotId returned from getBallotId ("
                .concat(newBallotId!.toString())
                .concat(") does not match the one retrieved directly from owners (")
                .concat(newStoredId!.toString())
                .concat(").")
            )
        }
        else {
            log(
                "Added a new record to the owners structure: owners["
                .concat(self.testAddress.toString())
                .concat("] = ")
                .concat(newStoredId!.toString())
            )
        }

        // Cool. If I got to this point, remove the bogus records and check that the dictionaries were correctly modified
        self.ownerControlRef.removeBallotOwner(ballotId: testId, ballotOwner: self.testAddress)
        self.ownerControlRef.removeOwner(ballotOwner: self.testAddress, ballotId: testId)

        // Same as above: If I repeat the instructions above, there should be a couple of ContractDataInconsistent events being emitted
        self.ownerControlRef.removeBallotOwner(ballotId: testId, ballotOwner: self.testAddress)
        self.ownerControlRef.removeOwner(ballotOwner: self.testAddress, ballotId: testId)

        newBallotOwners = self.ownerControlRef.getBallotOwners()
        newOwners = self.ownerControlRef.getOwners()

        if (newBallotOwners != {}) {
            panic(
                "ERROR: The ballotOwners dictionary was not cleared correctly. The dictionary is not yet empty!"
            )
        }
        else if (newOwners != {}) {
            panic(
                "ERROR: The owners dictionary was not cleared correctly. The dictionary is not yet empty!"
            )
        }
        else {
            log(
                "Both owners and ballotOwners were cleared out correctly!"
            )
        }
    }
}
// NOTE: This stupid, stupid transaction crashes by no apparent reason when run in the normal emulator. But, if run as a test, it works fine! Go figure... The Flow dudes need to fix the CLI ASAP!

// LOL! This is actually working as it is supposed to!! The objective with setting the 'set' and 'remove' functions from the OwnerControl resource is to prevent these from being executed from outside of the account (hence why I created those with access(account)), i.e., these can only be executed from within other resources stored in the same account (such as from within the BallotPrinterAdmin resource), which is the contract deployer (Admin) account! I should NOT be able to directly execute these functions from outside of the account, such as this transaction for instance, hence why it is complaining about it!!! As it should! This shit is actually working as I want it to!!

import "VoteBoothST"

transaction(someAddress: Address, anotherAddress: Address) {
    let ownerControlRef: auth(VoteBoothST.Admin) &VoteBoothST.OwnerControl
    let ownerAddress: Address
    let testAddress: Address
    let ballotPrinterRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.ownerAddress = signer.address
        self.testAddress = someAddress
        // Test the OwnerControl resource by pulling an authorized reference and running some functions of it
        self.ownerControlRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.OwnerControl>(from: VoteBoothST.ownerControlStoragePath)
        ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.OwnerControl at "
            .concat(VoteBoothST.ownerControlPublicPath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )

        // I need a printerAdminRef to mint a few test Ballots!
        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin at "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )
    }

    execute {
        /*
            Use the OwnerControl reference to check that both the ballotOwner and owners internal dictionaries were created empty. Safe to say that this function should only be called right after the contract is deployed. After that, the expectation is that these structures are going to be filled
        */
        var ballotOwners: {UInt64: Address} = self.ownerControlRef.getBallotOwners()
        
        if (ballotOwners != {}) {
            panic(
                "ERROR: The OwnerControl resource at "
                .concat(VoteBoothST.ownerControlStoragePath.toString())
                .concat(" has a non-empty ballotOwners dictionary in it!")
            )
        }

        var owners: {Address: UInt64} = self.ownerControlRef.getOwners()

        if (owners != {}) {
            panic(
                "ERROR: The OwnerControl resource at "
                .concat(VoteBoothST.ownerControlStoragePath.toString())
                .concat(" has a non-empty owners dictionary in it!")
            )
        }

        if (VoteBoothST.printLogs) {
            // If all went OK, log a simple message acknowledging it
            log(
                "The OwnerControl resource at "
                .concat(VoteBoothST.ownerControlStoragePath.toString())
                .concat(" for account ")
                .concat(self.ownerAddress.toString())
                .concat(" is consistent. ballotOwners and owners are still empty.")
            )
        }

        /*
            I've devised the OwnerControl resource with set and remove function that have 'access(account)' as access control. This means that to set or remove entries to the ballotOwners and owners dictionaries can only happen through contract functions or other resources stored in the same account.
            So, knowing this, I've restricted this function to the printBallot and burnBallot function from the ballotPrinterAdmin resource, which in itself if already restricted with the VoteBoothST.Admin entitlement! In other words, only the contract deployer has this entitlement (because I've defined it in the contract itself) and only he/she can get an authorized reference to use the printBallot and burnBallot functions.
            This to say that, the only way I have to change these dictionaries is to print and burn Ballots, and only the contract deployer is able to sign a transaction (this one) to do so.
        */

        // Lets print a pair of Ballots and check if the OwnerControl internal dictionaries are consistent
        let testBallot01: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: someAddress)

        let testBallot02: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: anotherAddress)

        // Grab the ids and owners of the produced Ballots and check that these match with the ones in the ballotOwners and owners dictionaries

        let testBallot01Id: UInt64 = testBallot01.id
        let testBallot02Id: UInt64 = testBallot02.id

        let testBallot01Owner: Address = testBallot01.ballotOwner
        let testBallot02Owner: Address = testBallot02.ballotOwner

        // I've added a simple consistency checking function that checks if the lengths of both internal dictionaries match. A mismatch indicated a problem and this function returns false.
        if (!self.ownerControlRef.isConsistent()) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.ballotOwners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while the owners dictionary has ")
                .concat(self.ownerControlRef.getBallotCount().toString())
                .concat(" entries! These need to match!")
            )
        }

        // If the previous check didn't blew this thing up, check that the counts are 2 in each dictionary
        if (self.ownerControlRef.getOwnersCount() != 2) {
            panic(
                "ERROR: The OwnerControl.ballotOwners has "
                .concat(self.ownerControlRef.getOwnersCount().toString())
                .concat(" entries, while 2 where expected!")
            )
        }
        else if (self.ownerControlRef.getBallotCount() != 2) {
            panic(
                "ERROR: The OwnerControl.owners has "
                .concat(self.ownerControlRef.getBallotCount().toString())
                .concat(" entries, while 2 where expected!")
            )
        }

        // All good so far. Check that entries do match
        let storedBallot01Id: UInt64? = self.ownerControlRef.getBallotId(owner: testBallot01Owner)
        let storedBallot02Id: UInt64? = self.ownerControlRef.getBallotId(owner: testBallot02Owner)

        let storedBallot01Owner: Address? = self.ownerControlRef.getBallotOwner(ballotId: testBallot01Id)
        let storedBallot02Owner: Address? = self.ownerControlRef.getBallotOwner(ballotId: testBallot02Id)

        // Check if all this data matches. Contract data consistency is fundamental
        if (storedBallot01Id == nil) {
            panic(
                "ERROR: There's no valid Id record in owners dictionary for testBallot01 with id "
                .concat(testBallot01Id.toString())
                .concat(" for owner ")
                .concat(testBallot01Owner.toString())
                .concat(". Got a nil instead!")
            )
        }
        else if (storedBallot02Id == nil) {
            panic(
                "ERROR: There's no valid Id record in the owners dictionary for testBallotO2 with id "
                .concat(testBallot02Id.toString())
                .concat(" for owner ")
                .concat(testBallot02Owner.toString())
                .concat(". Got a nil instead!")
            )
        }
        else if (storedBallot01Owner == nil) {
            panic(
                "ERROR: There's no valid Owner record in the ballotOwners dictionary for testBallot01 with id "
                .concat(testBallot01Id.toString())
                .concat(" for owner ")
                .concat(testBallot01Owner.toString())
                .concat(". Got a nil instead!")
            )
        }
        else if (storedBallot02Owner == nil) {
            panic(
                "ERROR: There's no valid Owner record in the ballotOwners dictionary for testBallot02 with id "
                .concat(testBallot02Id.toString())
                .concat(" for owner ")
                .concat(testBallot02Owner.toString())
                .concat(". Got a nil instead!")
            )
        }

        // No nils in the returned data. Check if all the data is still consistent at the value level.
        if (testBallot01Id != storedBallot01Id!) {
            panic(
                "ERROR: Contract Data mismatch detected! TestBallot01 was minted with id "
                .concat(testBallot01Id.toString())
                .concat(" but the owners dictionary stored id ")
                .concat(storedBallot01Id!.toString())
                .concat(" instead! These need to match!")
            )
        }
        else if (testBallot02Id != storedBallot02Id!) {
            panic(
                "ERROR: Contract Data mismatch detected! TestBallot02 was minted with id "
                .concat(testBallot02Id.toString())
                .concat(" but the owners dictionary stored id ")
                .concat(storedBallot02Id!.toString())
                .concat(" instead! These need to match!")
            )
        }
        else if (testBallot01Owner != storedBallot01Owner!) {
            panic(
                "ERROR: Contract Data mismatch detected! TestBallot01 was minted with owner "
                .concat(testBallot01Owner.toString())
                .concat(" but the ballotOwners dictionary stored owner ")
                .concat(storedBallot01Owner!.toString())
                .concat(" instead! These need to match!")
            )
        }
        else if (testBallot02Owner != storedBallot02Owner!) {
            panic(
                "ERROR: Contract Data mismatch detected! TestBallot02 was minted with owner "
                .concat(testBallot02Owner.toString())
                .concat(" but the ballotOwners dictionary stored owner ")
                .concat(storedBallot02Owner!.toString())
                .concat(" instead! These need to match!")
            )
        }

        // All done. Burn the Ballots
        self.ballotPrinterRef.burnBallot(ballotToBurn: <- testBallot01)
        self.ballotPrinterRef.burnBallot(ballotToBurn: <- testBallot02)

        ballotOwners = self.ownerControlRef.getBallotOwners()
        owners = self.ownerControlRef.getOwners()

        if (ballotOwners != {}) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.ballotOwners should be empty but currently has "
                .concat(ballotOwners.length.toString())
                .concat(" entries still!")
            )
        }
        else if (owners != {}) {
            panic(
                "ERROR: Contract Data inconsistency detected! The OwnerControl.owners should be empty but currently has "
                .concat(owners.length.toString())
                .concat(" entries still!")
            )
        }
    }
}
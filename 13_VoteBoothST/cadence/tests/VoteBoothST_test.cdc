import Test
import BlockchainHelpers
import "VoteBoothST"
import "NonFungibleToken"

access(all) let electionName: String = "World's best dog ever!"
access(all) let electionSymbol: String = "WBDE"
access(all) let electionLocation: String = "Campinho"
access(all) let electionBallot: String = "Who was the best dog this summer? Options: \n1 - Eddie, \n2 - Argus, \n3 - Both, \n4 - None"
access(all) let electionOptions: String = "1;2;3;4"

access(all) let expectedBallotPrinterAdminStoragePath: StoragePath = /storage/BallotPrinterAdmin
access(all) let expectedBallotPrinterAdminPublicPath: PublicPath = /public/BallotPrinterAdmin
access(all) let expectedBallotCollectionStoragePath: StoragePath = /storage/BallotCollection
access(all) let expectedBallotCollectionPublicPath: PublicPath = /public/BallotCollection
access(all) let expectedVoteBoxStoragePath: StoragePath = /storage/VoteBox
access(all) let expectedVoteBoxPublicPath: PublicPath = /public/VoteBox

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000008)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let account04: Test.TestAccount = Test.createAccount()
access(all) let account05: Test.TestAccount = Test.createAccount()

access(all) let accounts: [Test.TestAccount] = [account01, account02, account03, account04, account05]
access(all) let ballots: {String: {String: String}} = {}

// TRANSACTIONS
access(all) let testBallotPrinterTx: String = "../transactions/01_test_ballot_printer_admin.cdc"
access(all) let testBallotPrinterAdminTx: String = "../transactions/02_test_ballot_printer_admin_reference.cdc"
access(all) let testBallotCollectionLoadTx: String = "../transactions/03_test_ballot_collection_load.cdc"
access(all) let testBallotCollectionRefTx: String = "../transactions/04_test_ballot_collection_reference.cdc"
access(all) let voteBoxCreationTx: String = "../transactions/05_create_vote_box.cdc"
access(all) let mintBallotToAccountTx: String = "../transactions/06_mint_ballot_to_account.cdc"
access(all) let withdrawBallotFromVoteBoxLoadTx: String = "../transactions/07_withdraw_ballot_from_vote_box_load.cdc"
access(all) let withdrawBallotFromVoteBoxRefTx: String = "../transactions/08_withdraw_ballot_from_vote_box_ref.cdc"

// SCRIPTS
access(all) let testVoteBoxSc: String = "../scripts/01_test_vote_box.cdc"
access(all) let getVoteOptionsSc: String = "../scripts/02_get_vote_option.cdc"
access(all) let getIDsSc: String = "../scripts/03_get_IDs.cdc"

// EVENTS
// NonFungibleToken events
access(all) let updatedEventType: Type = Type<NonFungibleToken.Updated>()
access(all) let withdrawnEventType: Type = Type<NonFungibleToken.Withdrawn>()
access(all) let depositedEventType: Type = Type<NonFungibleToken.Deposited>()
access(all) let resourceDestroyedEventType: Type = Type<NonFungibleToken.NFT.ResourceDestroyed>()

// VoteBoothST Events
access(all) let nonNilTokenReturnedEventType: Type = Type<VoteBoothST.NonNilTokenReturned>()
access(all) let ballotMintedEventType: Type = Type<VoteBoothST.BallotMinted>()
access(all) let ballotSubmittedEventType: Type = Type<VoteBoothST.BallotSubmitted>()
access(all) let ballotModifiedEventType: Type = Type<VoteBoothST.BallotModified>()
access(all) let ballotBurnedEventType: Type = Type<VoteBoothST.BallotBurned>()
access(all) let contractDataInconsistentEventType: Type = Type<VoteBoothST.ContractDataInconsistent>()
access(all) let voteBoxCreatedEventType: Type = Type<VoteBoothST.VoteBoxCreated>()
access(all) let ballotCollectionCreatedEventType: Type = Type<VoteBoothST.BallotCollectionCreated>()

// Use the following dictionary to keep track of the number of events expected. The way Cadence tests work, new events are just added to the list of existing events, so to determine the success (or unsuccess) of an operation, I need to check the number of events for a given type detected in the test instance of the blockchain
access(all) var eventNumberCount: {Type: Int} = {
    updatedEventType: 0,
    withdrawnEventType: 0,
    depositedEventType: 0,
    resourceDestroyedEventType: 0,
    nonNilTokenReturnedEventType: 0,
    ballotMintedEventType: 0,
    ballotSubmittedEventType: 0,
    ballotModifiedEventType: 0,
    ballotBurnedEventType: 0,
    contractDataInconsistentEventType: 0,
    voteBoxCreatedEventType: 0,
    ballotCollectionCreatedEventType: 0
}

access(all) fun setup() {
    let err: Test.Error? = Test.deployContract(
        name: "VoteBoothST",
        path: "../contracts/VoteBoothST.cdc",
        arguments: [electionName, electionSymbol, electionBallot, electionLocation, electionOptions]
    )

    Test.expect(err, Test.beNil())

    // Test that the BallotCollection event was emitted
    var ballotCollectionCreatedEvents: [AnyStruct] = Test.eventsOfType(ballotCollectionCreatedEventType)

    // Test that one and only one event of this type was emitted
    eventNumberCount[ballotCollectionCreatedEventType] = eventNumberCount[ballotCollectionCreatedEventType]! + 1
    Test.assertEqual(ballotCollectionCreatedEvents.length, eventNumberCount[ballotCollectionCreatedEventType]!)

    // Test that the address in the event matched the deployer and none else
    let ballotCollectionCreatedEvent: VoteBoothST.BallotCollectionCreated = ballotCollectionCreatedEvents[0] as! VoteBoothST.BallotCollectionCreated

    Test.assertEqual(deployer.address, ballotCollectionCreatedEvent._accountAddress)
}

access(all) fun _testGetElectionName() {
    Test.assertEqual(electionName, VoteBoothST.getElectionName())
}
access(all) fun _testGetElectionSymbol() {
    Test.assertEqual(electionSymbol, VoteBoothST.getElectionSymbol())
}
access(all) fun _testGetElectionBallot() {
    Test.assertEqual(electionBallot, VoteBoothST.getElectionBallot())
}
access(all) fun _testGetElectionLocation() {
    Test.assertEqual(electionLocation, VoteBoothST.getElectionLocation())
}
access(all) fun _testGetElectionOptions() {
    let options: [UInt64] = VoteBoothST.getElectionOptions()

    var parsedElectionOptions: [UInt64] = []
    var optionElements: [String] = electionOptions.split(separator: ";")
    var currentElement: UInt64? = nil

    for optionElement in optionElements {
        currentElement = UInt64.fromString(optionElement)

        if (currentElement != nil) {
            parsedElectionOptions.append(currentElement!)
        }
    }

    Test.assertEqual(parsedElectionOptions, options)
}

// Continue with the constructor assertions
access(all) fun _testDefaultPaths() {
    Test.assertEqual(VoteBoothST.ballotPrinterAdminStoragePath, expectedBallotPrinterAdminStoragePath)

    Test.assertEqual(VoteBoothST.ballotPrinterAdminPublicPath, expectedBallotPrinterAdminPublicPath)

    Test.assertEqual(VoteBoothST.ballotCollectionStoragePath, expectedBallotCollectionStoragePath)

    Test.assertEqual(VoteBoothST.ballotCollectionPublicPath, expectedBallotCollectionPublicPath)

    Test.assertEqual(VoteBoothST.voteBoxPublicPath, expectedVoteBoxPublicPath)

    Test.assertEqual(VoteBoothST.voteBoxStoragePath, expectedVoteBoxStoragePath)
}

access(all) fun _testDefaultParameters() {
    Test.assertEqual(VoteBoothST.totalBallotsMinted, 0 as UInt64)
    Test.assertEqual(VoteBoothST.totalBallotsSubmitted, 0 as UInt64)

    Test.assert(VoteBoothST.getBallotOwners() == {})

    Test.assert(VoteBoothST.getOwners() == {})


}

access(all) fun _testMinterLoading() {
    // Run the corresponding transaction
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotPrinterTx,
        [],
        deployer
    )

    // This transaction should emit a bunch of events and, if all, goes well, should NOT emit a warning event.
    Test.expect(txResult01, Test.beSucceeded())

    var ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // If the transaction was OK, the first 3 events should have been emitted, but not the 4th one. As such, start by increase the successful event counter by one before comparing
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Try to run the same transaction, but now signed by someone that is not authorized to access the resource. The expectation is for it to fail
    let txResult02: Test.TransactionResult = executeTransaction(
        testBallotPrinterTx,
        [],
        account01
    )

    Test.expect(txResult02, Test.beFailed())

    // Also, this transaction should not emit any of the events from before, therefore the number of events emitted in the meantime should remain unchanged
    // Recapture the events again
    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // And check that they haven't changed the count
    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)
}

access(all) fun _testMinterReference() {
    // This transaction runs a similar function but using references instead of loading the resource
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotPrinterAdminTx,
        [],
        deployer
    )

    Test.expect(txResult01, Test.beSucceeded())

    var ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // The test blockchain does not resets the number of events between tests, therefore if this one was successful, I should have one more event added to the existing ones
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1


    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Repeat the transaction with an invalid (unauthorized) signer
    let txResult02: Test.TransactionResult = executeTransaction(
        testBallotPrinterAdminTx,
        [],
        account01
    )

    Test.expect(txResult02, Test.beFailed())

    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // Same as before, the event quantities should remain unchanged
    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)
}

// Test the 3rd transaction signing it with a user that should not be able to do the things in the transaction text
access(all) fun _testBallotCollectionLoad() {
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotCollectionLoadTx,
        [],
        deployer
    )

    // The expectation is for this transaction to run if signed by the deployer, but not if anyone else signs it instead
    Test.expect(txResult01, Test.beSucceeded())

    var ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // The transaction should increment the successful events number by one
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Run the transaction again, but with an invalid signer now
    let txResult02: Test.TransactionResult = executeTransaction(
        testBallotCollectionLoadTx,
        [],
        account01
    )

    Test.expect(txResult02, Test.beFailed())

    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // The event quantities must have remained unchanged. Test it
    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)
}

access(all) fun _testBallotCollectionRef() {
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotCollectionRefTx,
        [],
        deployer
    )

    // As before, the expectation is that this transaction works with the deployer but with no one else
    Test.expect(txResult01, Test.beSucceeded())

    // Check the usual events
    var ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // The successful transaction should increment the successful events number by one
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Repeat the transaction but with the wrong signer. Everything must fail
    let txResult02: Test.TransactionResult = executeTransaction(
        testBallotCollectionRefTx,
        [],
        account01
    )

    Test.expect(txResult02, Test.beFailed())

    // Check that the event array did not changed
    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)
}

access(all) fun testCreateVoteBox() {
    // Create a VoteBox for each of the additional user accounts (account01 and account02)
    let txResult01: Test.TransactionResult = executeTransaction(
        voteBoxCreationTx,
        [],
        account01
    )

    Test.expect(txResult01, Test.beSucceeded())

    var voteBoxCreatedEvents: [AnyStruct] = Test.eventsOfType(voteBoxCreatedEventType)

    eventNumberCount[voteBoxCreatedEventType] = eventNumberCount[voteBoxCreatedEventType]! + 1
    Test.assertEqual(voteBoxCreatedEvents.length, eventNumberCount[voteBoxCreatedEventType]!)

    // Extract the event details and validate that the address emitted matched the transaction signer
    var voteBoxCreatedEvent: VoteBoothST.VoteBoxCreated = voteBoxCreatedEvents[voteBoxCreatedEvents.length - 1] as! VoteBoothST.VoteBoxCreated

    var voteBoxAddress: Address = voteBoxCreatedEvent._voterAddress

    Test.assertEqual(voteBoxAddress, account01.address)

    // Repeat the process for account02
    let txResult02: Test.TransactionResult = executeTransaction(
        voteBoxCreationTx,
        [],
        account02
    )

    Test.expect(txResult01, Test.beSucceeded())

    // If the transaction was successful, increase the number of expected successful events

    voteBoxCreatedEvents = Test.eventsOfType(voteBoxCreatedEventType)
    eventNumberCount[voteBoxCreatedEventType] = eventNumberCount[voteBoxCreatedEventType]! + 1

    Test.assertEqual(voteBoxCreatedEvents.length, eventNumberCount[voteBoxCreatedEventType]!)

    voteBoxCreatedEvent = voteBoxCreatedEvents[voteBoxCreatedEvents.length - 1] as! VoteBoothST.VoteBoxCreated

    voteBoxAddress = voteBoxCreatedEvent._voterAddress

    Test.assertEqual(voteBoxAddress, account02.address)

    // NOTE: The way I've setup these transaction and the VoteBox resource itself, running this transaction again replaces the existing VoteBox, which can have some Ballots in it, for another "clean" one. Be careful with this
}

access(all) fun testBallotMintingToVoteBoxes() {
    // NOTE: This test assumes that the "testCreateVoteBox" has run successfully first, i.e., account01 and account02 have a valid VoteBox in their storage area and a public capability published.
    // NOTE2: This is just a simplified version of the next function, mainly to test the transaction 07 that allows for bulk minting of ballots. Since I destroy all ballots after the test, I need to do this one before.

    // TODO: This one
}

access(all) fun testBallotMintingToVoteBox() {
    // NOTE: This test assumes that the "testCreateVoteBox" has run successfully first, i.e., account01 and account02 have a valid VoteBox in their storage area and a public capability published.

    // Mint and deposit a new Ballot to account01. Use the event emitted to retrieve the ballotId
    let txResult01: Test.TransactionResult = executeTransaction(
        mintBallotToAccountTx,
        [account01.address],
        deployer
    )

    Test.expect(txResult01, Test.beSucceeded())

    var ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // In this case, the transaction mints and deposits the Ballot into a VoteBox and nothing else. Therefore only the ballotMinted events are going to be incremented
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Retrieve and compare the ballot id for this Ballot
    var ballotMintedEvent: VoteBoothST.BallotMinted = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

    let eventBallotId01: UInt64 = ballotMintedEvent._ballotId

    // Grab the Ballot Id using the getIDs script
    let scResult01: Test.ScriptResult = executeScript(
        getIDsSc,
        [account01.address]
    )

    // Extract the script results
    var storedBallotIDs: [UInt64] = (scResult01.returnValue as! [UInt64]?)!

    // There should be one and only one ballot in account01's VoteBox
    Test.assertEqual(storedBallotIDs.length, 1)

    // Extract and compare the two ballot ids
    Test.assertEqual(eventBallotId01, storedBallotIDs[storedBallotIDs.length - 1])

    // Repeat the process for account02
    let txResult02: Test.TransactionResult = executeTransaction(
        mintBallotToAccountTx,
        [account02.address],
        deployer
    )

    Test.expect(txResult02, Test.beSucceeded())

    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // Only the BallotMinted event counter should be incremented
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    ballotMintedEvent = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

    let eventBallotId02: UInt64 = ballotMintedEvent._ballotId

    let scResult02: Test.ScriptResult = executeScript(
        getIDsSc,
        [account02.address]
    )

    storedBallotIDs = (scResult02.returnValue as! [UInt64]?)!

    Test.assertEqual(storedBallotIDs.length, 1)
    Test.assertEqual(eventBallotId02, storedBallotIDs[storedBallotIDs.length - 1])
}


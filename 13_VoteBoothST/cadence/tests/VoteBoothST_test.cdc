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
access(all) let expectedOwnerControlStoragePath: StoragePath = /storage/ownerControl
access(all) let expectedOwnerControlPublicPath: PublicPath = /public/ownerControl

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000008)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let account04: Test.TestAccount = Test.createAccount()
access(all) let account05: Test.TestAccount = Test.createAccount()

access(all) let accounts: [Test.TestAccount] = [account01, account02, account03, account04, account05]

// The idea is to use this dictionary to establish a quick way to validate a Ballot in a given account.
/*
    To simplify things, I've built the whole thing with Strings. This should be populated as
    "account name": {
            "address": <ADDRESS>,
            "ballotID": <BALLOT_ID>
            }
*/
access(all) let ballots: {String: {String: String}} = {}

access(all) let addresses: [Address] = [account01.address, account02.address, account03.address, account04.address, account05.address]

// TRANSACTIONS
access(all) let testOwnerControlTx: String = "../transactions/01_test_owner_control.cdc"
access(all) let testBallotPrinterTx: String = "../transactions/02_test_ballot_printer_admin.cdc"
access(all) let testBallotPrinterAdminTx: String = "../transactions/03_test_ballot_printer_admin_reference.cdc"
access(all) let testBallotCollectionLoadTx: String = "../transactions/04_test_ballot_collection_load.cdc"
access(all) let testBallotCollectionRefTx: String = "../transactions/05_test_ballot_collection_reference.cdc"
access(all) let voteBoxCreationTx: String = "../transactions/06_create_vote_box.cdc"
access(all) let testBallotTx: String = "../transactions/07_test_ballot.cdc"
access(all) let mintBallotToAccountTx: String = "../transactions/08_mint_ballot_to_account.cdc"
access(all) let mintBallotsToAccountsTx: String = "../transactions/09_mint_ballots_to_accounts.cdc"
access(all) let withdrawBallotFromVoteBoxLoadTx: String = "../transactions/10_withdraw_ballot_from_vote_box_load.cdc"
access(all) let withdrawBallotFromVoteBoxRefTx: String = "../transactions/11_withdraw_ballot_from_vote_box_ref.cdc"
access(all) let burnBallotTx: String = "../transactions/12_burn_ballot.cdc"

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

access(all) fun testGetElectionName() {
    Test.assertEqual(electionName, VoteBoothST.getElectionName())
}
access(all) fun testGetElectionSymbol() {
    Test.assertEqual(electionSymbol, VoteBoothST.getElectionSymbol())
}
access(all) fun testGetElectionBallot() {
    Test.assertEqual(electionBallot, VoteBoothST.getElectionBallot())
}
access(all) fun testGetElectionLocation() {
    Test.assertEqual(electionLocation, VoteBoothST.getElectionLocation())
}
access(all) fun testGetElectionOptions() {
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
access(all) fun testDefaultPaths() {
    Test.assertEqual(VoteBoothST.ballotPrinterAdminStoragePath, expectedBallotPrinterAdminStoragePath)

    Test.assertEqual(VoteBoothST.ballotPrinterAdminPublicPath, expectedBallotPrinterAdminPublicPath)

    Test.assertEqual(VoteBoothST.ballotCollectionStoragePath, expectedBallotCollectionStoragePath)

    Test.assertEqual(VoteBoothST.ballotCollectionPublicPath, expectedBallotCollectionPublicPath)

    Test.assertEqual(VoteBoothST.voteBoxPublicPath, expectedVoteBoxPublicPath)

    Test.assertEqual(VoteBoothST.voteBoxStoragePath, expectedVoteBoxStoragePath)

    Test.assertEqual(VoteBoothST.ownerControlStoragePath, expectedOwnerControlStoragePath)

    Test.assertEqual(VoteBoothST.ownerControlPublicPath, expectedOwnerControlPublicPath)
}

access(all) fun testDefaultParameters() {
    Test.assertEqual(VoteBoothST.totalBallotsMinted, 0 as UInt64)
    Test.assertEqual(VoteBoothST.totalBallotsSubmitted, 0 as UInt64)
}

access(all) fun _testOwnerControl() {
    let txResult: Test.TransactionResult = executeTransaction(
        testOwnerControlTx,
        [account01.address],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // This transaction should trigger 4 ContractDataInconsistent events. Check if that was the case
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    eventNumberCount[contractDataInconsistentEventType] = eventNumberCount[contractDataInconsistentEventType]! + 4

    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)
}

access(all) fun testMinterLoading() {
    // Run the corresponding transaction
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotPrinterTx,
        [],
        deployer
    )

    // This transaction is expected to fail in all circumstances! Check the transaction text for a detailed explanation.
    Test.expect(txResult01, Test.beFailed())
}

access(all) fun testMinterReference() {
    // This transaction runs a similar function but using references instead of loading the resource
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotPrinterAdminTx,
        [account01.address],
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
        [account02.address],
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

access(all) fun testBallotCollectionLoad() {
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotCollectionLoadTx,
        [account01.address],
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

access(all) fun testBallotCollectionRef() {
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotCollectionRefTx,
        [account02.address],
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

access(all) fun _testCreateVoteBox() {
    // Create a VoteBox for each of the additional user accounts (account01 and account02)
    let txResult01: Test.TransactionResult = executeTransaction(
        voteBoxCreationTx,
        [],
        account01
    )

    Test.expect(txResult01, Test.beSucceeded())

    var voteBoxCreatedEvents: [AnyStruct] = Test.eventsOfType(voteBoxCreatedEventType)
    var resourceDestroyedEvents: [AnyStruct] = []

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

    /*
        NOTE: The way I've setup these transaction and the VoteBox resource itself, running this transaction again replaces the existing VoteBox, which can have some Ballots in it, for another "clean" one. Be careful with this

        NOTE2: This transaction "cleans" the storage spot to where the VoteBox is to be stored. This is done by "blindly" loading whatever is stored in the provided storage path into a variable and then destroying it. Update the event counter for this case
    */

    // Capture and log the last of these resourceDestroyed events just to confirm my suspicion
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)

    eventNumberCount[resourceDestroyedEventType] = resourceDestroyedEvents.length

}

access(all) fun _testBallot() {
    let txResult: Test.TransactionResult = executeTransaction(
        testBallotTx,
        [],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // The test ballot transaction should have emitted a pair of events. Test those too
    let ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    let ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    let resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    let contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    /*
    The BallotMinted events should have a new one and the resource destroyed events should have another one. Now, the trick is, the ResourceDestroyed event is only emitted when a NFT, as in a NonFungibleToken.NFT resource is destroyed. This is because the event itself is defined under the NFT standard definition, namely, NonFungibleToken.NFT.ResourceDestroyed, which means that the destruction of the VoteBox, which also happens in this transaction, does not emits this event, therefore it should not be taken into account.
    
    NOTE: the Ballot resource was destroyed with the 'destroy' function and not burned. No BallotBurned events should be emitted. Adjust the counters accordingly
    */
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    // Validate the counters
    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

}

access(all) fun _testBallotMintingToVoteBox() {
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

/*
    This test is simply a generalisation for the same test using the singular tense. All this does is to run the testCreateVoteBox but using a for cycle to automate stuff.

    NOTE: This function and the next one are exclusive to the non-looped versions of the same functions
    IMPORTANT: only one pair of these function should be "active", i.e., the name of the test function starts with "test". I'm using an underscore (_) to before the test part to deactivate the function
*/
access(all) fun _testCreateVoteBoxes() {
    var txResult: Test.TransactionResult? = nil
    var voteBoxCreatedEvents: [AnyStruct] = []
    var voteBoxCreatedEvent: VoteBoothST.VoteBoxCreated? = nil
    var voteBoxAddress: Address? = nil
    
    for account in accounts {
        txResult= executeTransaction(
            voteBoxCreationTx,
            [],
            account
        )

        // Test if the transaction was successful
        Test.expect(txResult, Test.beSucceeded())

        // Grab the expected events to the proper structure
        voteBoxCreatedEvents = Test.eventsOfType(voteBoxCreatedEventType)

        // Increment the number of expected events from the main counter structure
        eventNumberCount[voteBoxCreatedEventType] = eventNumberCount[voteBoxCreatedEventType]! + 1

        // Check now if all quantities are matched OK
        Test.assertEqual(voteBoxCreatedEvents.length, eventNumberCount[voteBoxCreatedEventType]!)

        // Check also that the addresses emitted in the events matches the account used to sign the transaction
        voteBoxCreatedEvent = voteBoxCreatedEvents[voteBoxCreatedEvents.length - 1] as! VoteBoothST.VoteBoxCreated

        voteBoxAddress = voteBoxCreatedEvent!._voterAddress

        Test.assertEqual(voteBoxAddress!, account.address)

        log(
            "Successfully created a VoteBox for account "
            .concat(account.address.toString())
        )
    }

}

/*
    This function, unlike the preceding one, serves mainly to test the transaction that mints and transfers NFTs in bulk
*/
access(all) fun _testBallotMintingToVoteBoxes() {
    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil
    var storedBallotIds: [UInt64] = []

    var ballotMintedEvents: [AnyStruct] = []
    var ballotBurnedEvents: [AnyStruct] = []
    var resourceDestroyedEvents: [AnyStruct] = []
    var contractDataInconsistentEvents: [AnyStruct] = []

    var ballotMintedEvent: VoteBoothST.BallotMinted? = nil

    txResult = executeTransaction(
        mintBallotsToAccountsTx,
        [addresses],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    log(
        "Successfully minted one Ballot for accounts "
    )

    for account in accounts {
        log(
            account.address.toString()
        )
    }

    // Populate the event structures
    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // Increment the minted events counter by the number of addresses in the input array
    // All the remaining structures should have not been changed
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + addresses.length

    // Validate the event count
    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Populate the ballot structure
    var ballotIDs: [UInt64] = []

    // Keep this value to ease further calculations, since I have the events that I care for the the end of the array 
    let maxEventIndex: Int = ballotMintedEvents.length - 1
    let maxAccountIndex: Int = accounts.length - 1

    for index, account in accounts {
        /*
            Grab the BallotMinted event that corresponds to the account element in question]
            The calculation of the index of the event is quite tricky...
            The problem resides in the fact that I have a fixed number of accounts (5) but an unknown number of corresponding events. All I know is, if things went OK, the event array should have a number of elements equal or greater than the number of accounts (I cannot guarantee that there are no previous events in the array).
            That said, the way to ensure that I'm not dependent from the length of the event array is to calculate the index as follows:

            accounts = [account01, account02, account03, account04, account05] => length: 5, max index: accounts.length - 1 = 4

            events = [..., acc01Event, acc02Event, acc03Event, acc04Event, acc05Event] => length: ?, max index: events.length - 1

            I need to set my base index for the events array where the "acc01Event" is and then navigate through the array by adding the index value
        */
        ballotMintedEvent = ballotMintedEvents[maxEventIndex - maxAccountIndex + index] as! VoteBoothST.BallotMinted

        // List and validate the number of Ballots and their IDs in each account
        scResult = executeScript(
            getIDsSc,
            [account.address]
        )

        storedBallotIds = (scResult!.returnValue as! [UInt64]?)!

        // Only one Ballot should exist per account
        Test.assertEqual(storedBallotIds.length, 1)
        // And the IDs need to match!
        Test.assertEqual(ballotMintedEvent!._ballotId, storedBallotIds[storedBallotIds.length - 1])
        // The voter address should also match the current account being used
        Test.assertEqual(ballotMintedEvent!._voterAddress, account.address)

        // If none of the asserts before blew up, all is good. Proceed with building the ballot dictionary
        ballots["account0".concat((index + 1).toString())] = {
            "address": ballotMintedEvent!._voterAddress.toString(),
            "ballotID": ballotMintedEvent!._ballotId.toString()
        }
    }
}

/* 
    This function follows on the previous ones, i.e., it expects a valid VoteBox in each account in the accounts array with one and only one Ballot in it (the burnBallot transaction already validates this). The transaction in question loads and burns it without required more information.
*/
access(all) fun _testBurnBallots() {
    var txResult: Test.TransactionResult? = nil
    var ballotMintedEvents: [AnyStruct] = []
    var ballotBurnedEvents: [AnyStruct] = []
    var resourceDestroyedEvents: [AnyStruct] = []
    var contractDataInconsistentEvents: [AnyStruct] = []

    var ballotBurnedEvent: VoteBoothST.BallotBurned? = nil
    var ballotBurnedId: UInt64 = 0
    var ballotEntry: {String: String} = {}
    
    for index, account in accounts {
        txResult = executeTransaction(
            burnBallotTx,
            [],
            account
        )

        // Check if the transaction was executed successfully
        Test.expect(txResult, Test.beSucceeded())

        // All good if I get here. Check the events and validate that the ids of the Ballots burned do match the ones in storage
        ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
        ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
        resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
        contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

        // Only the number of BallotBurned and ResourceDestroyed events should have been incremented by 1
        eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
        eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

        // Validate the event count
        Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
        Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
        Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
        Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

        // All cool. Proceed
        ballotBurnedEvent = ballotBurnedEvents[ballotBurnedEvents.length - 1] as! VoteBoothST.BallotBurned

        ballotBurnedId = ballotBurnedEvent!._ballotId
        ballotEntry = ballots["account0".concat((index + 1).toString())]!

        Test.assertEqual(ballotBurnedId.toString(), ballotEntry["ballotID"]!)

        // All good. Inform the user about it
        log(
            "Successfully burned a Ballot with ID "
            .concat(ballotBurnedId.toString())
            .concat(" from account ")
            .concat(ballotEntry["address"]!)
        )
    }
}

// TODO: Modify Ballots (Vote)
// TODO: Multiple Vote Casting
// TODO: Eligibility Module
// TODO: Tally Contract
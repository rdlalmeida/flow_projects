import Test
import BlockchainHelpers
import "VoteBoothST"
import "NonFungibleToken"

access(all) let electionName: String = "World's best dog ever!"
access(all) let electionSymbol: String = "WBDE"
access(all) let electionLocation: String = "Campinho"
access(all) let electionBallot: String = "Who was the best dog this summer? Options: \n1 - Eddie, \n2 - Argus, \n3 - Both, \n4 - None"
access(all) let electionOptions: String = "1;2;3;4"

// Use this flag to turn log printing on or off
access(all) let printLogs: Bool = false

access(all) let expectedBallotPrinterAdminStoragePath: StoragePath = /storage/BallotPrinterAdmin
access(all) let expectedBallotPrinterAdminPublicPath: PublicPath = /public/BallotPrinterAdmin
access(all) let expectedBallotBoxStoragePath: StoragePath = /storage/BallotBox
access(all) let expectedBallotBoxPublicPath: PublicPath = /public/BallotBox
access(all) let expectedVoteBoxStoragePath: StoragePath = /storage/VoteBox
access(all) let expectedVoteBoxPublicPath: PublicPath = /public/VoteBox
access(all) let expectedOwnerControlStoragePath: StoragePath = /storage/OwnerControl
access(all) let expectedOwnerControlPublicPath: PublicPath = /public/OwnerControl
access(all) let expectedBurnBoxStoragePath: StoragePath = /storage/BurnBox
access(all) let expectedBurnBoxPublicPath: PublicPath = /public/BurnBox

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000008)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let account04: Test.TestAccount = Test.createAccount()
access(all) let account05: Test.TestAccount = Test.createAccount()

access(all) let accounts: [Test.TestAccount] = [account01, account02, account03, account04, account05]

// The idea is to use this dictionary to establish a quick way to validate a Ballot in a given account, since dictionary translate directly to JSON object.
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
access(all) let testBallotBoxLoadTx: String = "../transactions/04_test_ballot_collection_load.cdc"
access(all) let testBallotBoxRefTx: String = "../transactions/05_test_ballot_collection_reference.cdc"
access(all) let voteBoxCreationTx: String = "../transactions/06_create_vote_box.cdc"
access(all) let testBallotTx: String = "../transactions/07_test_ballot.cdc"
access(all) let mintBallotToAccountTx: String = "../transactions/08_mint_ballot_to_account.cdc"
access(all) let mintBallotsToAccountsTx: String = "../transactions/09_mint_ballots_to_accounts.cdc"
access(all) let withdrawBallotToBurnBoxLoadTx: String = "../transactions/10_withdraw_ballot_to_burn_box_load.cdc"
access(all) let withdrawBallotToBurnBoxRefTx: String = "../transactions/11_withdraw_ballot_to_burn_box_ref.cdc"
access(all) let burnBallotFromBurnBoxTx: String = "../transactions/12_burn_ballots_from_burn_box.cdc"
access(all) let destroyVoteBoxTx: String = "../transactions/14_destroy_vote_box.cdc"

// SCRIPTS
access(all) let testVoteBoxSc: String = "../scripts/01_test_vote_box.cdc"
access(all) let getVoteOptionsSc: String = "../scripts/02_get_vote_option.cdc"
access(all) let getIDsSc: String = "../scripts/03_get_IDs.cdc"
access(all) let getBallotOwnerSc: String = "../scripts/04_get_ballot_owner.cdc"

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
access(all) let voteBoxDestroyedEventType: Type = Type<VoteBoothST.VoteBoxDestroyed>()
access(all) let ballotBoxCreatedEventType: Type = Type<VoteBoothST.BallotBoxCreated>()
access(all) let ballotSetToBurnEventType: Type = Type<VoteBoothST.BallotSetToBurn>()

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
    voteBoxDestroyedEventType: 0,
    ballotBoxCreatedEventType: 0,
    ballotSetToBurnEventType: 0
}

access(all) fun setup() {
    let err: Test.Error? = Test.deployContract(
        name: "VoteBoothST",
        path: "../contracts/VoteBoothST.cdc",
        arguments: [electionName, electionSymbol, electionBallot, electionLocation, electionOptions, printLogs]
    )

    Test.expect(err, Test.beNil())

    // Test that the BallotBox event was emitted
    var BallotBoxCreatedEvents: [AnyStruct] = Test.eventsOfType(ballotBoxCreatedEventType)

    // Test that one and only one event of this type was emitted
    eventNumberCount[ballotBoxCreatedEventType] = eventNumberCount[ballotBoxCreatedEventType]! + 1
    Test.assertEqual(BallotBoxCreatedEvents.length, eventNumberCount[ballotBoxCreatedEventType]!)

    // Test that the address in the event matched the deployer and none else
    let BallotBoxCreatedEvent: VoteBoothST.BallotBoxCreated = BallotBoxCreatedEvents[0] as! VoteBoothST.BallotBoxCreated

    Test.assertEqual(deployer.address, BallotBoxCreatedEvent._accountAddress)
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

    Test.assertEqual(VoteBoothST.ballotBoxStoragePath, expectedBallotBoxStoragePath)

    Test.assertEqual(VoteBoothST.ballotBoxPublicPath, expectedBallotBoxPublicPath)

    Test.assertEqual(VoteBoothST.voteBoxPublicPath, expectedVoteBoxPublicPath)

    Test.assertEqual(VoteBoothST.voteBoxStoragePath, expectedVoteBoxStoragePath)

    Test.assertEqual(VoteBoothST.ownerControlStoragePath, expectedOwnerControlStoragePath)

    Test.assertEqual(VoteBoothST.ownerControlPublicPath, expectedOwnerControlPublicPath)

    Test.assertEqual(VoteBoothST.burnBoxStoragePath, expectedBurnBoxStoragePath)

    Test.assertEqual(VoteBoothST.burnBoxPublicPath, expectedBurnBoxPublicPath)
}

access(all) fun testDefaultParameters() {
    Test.assertEqual(VoteBoothST.totalBallotsMinted, 0 as UInt64)
    Test.assertEqual(VoteBoothST.totalBallotsSubmitted, 0 as UInt64)
}

access(all) fun testOwnerControl() {
    let txResult: Test.TransactionResult = executeTransaction(
        testOwnerControlTx,
        [account01.address, account02.address],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // This transaction mints and burns two ballots. Adjust the eventCounter dictionary accordingly and check if the events emitted match what is expected
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 2
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 2
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 2

    // No ContractDataInconsistent events should have been emitted. This entry should still be 0

    // Check the usual event structured
    var ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
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

    if (VoteBoothST.printLogs) {
        log(
            "test_ballot_printer_admin_ref: Current BallotBurned events = "
            .concat(ballotBurnedEvents.length.toString())
        )
    }
}

access(all) fun testBallotBoxLoad() {
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotBoxLoadTx,
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
        testBallotBoxLoadTx,
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

    if (VoteBoothST.printLogs) {
        log(
            "test_ballot_collection_load: Current BallotBurned events = "
            .concat(ballotBurnedEvents.length.toString())
        )
    }
}

access(all) fun testBallotBoxRef() {
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotBoxRefTx,
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
        testBallotBoxRefTx,
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

    if (VoteBoothST.printLogs) {
        log(
            "test_ballot_collection_reference: BallotBurned events = "
            .concat(ballotBurnedEvents.length.toString())
        )
    }
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

    Test.expect(txResult02, Test.beSucceeded())

    // If the transaction was successful, increase the number of expected successful events

    voteBoxCreatedEvents = Test.eventsOfType(voteBoxCreatedEventType)
    eventNumberCount[voteBoxCreatedEventType] = eventNumberCount[voteBoxCreatedEventType]! + 1

    Test.assertEqual(voteBoxCreatedEvents.length, eventNumberCount[voteBoxCreatedEventType]!)

    voteBoxCreatedEvent = voteBoxCreatedEvents[voteBoxCreatedEvents.length - 1] as! VoteBoothST.VoteBoxCreated

    voteBoxAddress = voteBoxCreatedEvent._voterAddress

    Test.assertEqual(voteBoxAddress, account02.address)

    let txResult03: Test.TransactionResult = executeTransaction(
        voteBoxCreationTx,
        [],
        account03
    )

    Test.expect(txResult03, Test.beSucceeded())

    voteBoxCreatedEvents = Test.eventsOfType(voteBoxCreatedEventType)
    eventNumberCount[voteBoxCreatedEventType] = eventNumberCount[voteBoxCreatedEventType]! + 1

    Test.assertEqual(voteBoxCreatedEvents.length, eventNumberCount[voteBoxCreatedEventType]!)

    voteBoxCreatedEvent = voteBoxCreatedEvents[voteBoxCreatedEvents.length - 1] as! VoteBoothST.VoteBoxCreated

    voteBoxAddress = voteBoxCreatedEvent._voterAddress

    Test.assertEqual(voteBoxAddress, account03.address)
    /*
        NOTE: I've updated the createVoteBox transaction to panic (revert) if there's a VoteBox already in storage, regardless of it's empty or not. The rationale is that I want to prevent accidentally destroying a VoteBox with a valid Ballot in it.
    */

    // Capture and log the last of these resourceDestroyed events just to confirm my suspicion
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)

    eventNumberCount[resourceDestroyedEventType] = resourceDestroyedEvents.length

}

access(all) fun testBallot() {
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotTx,
        [account03.address],
        deployer
    )

    Test.expect(txResult01, Test.beSucceeded())

    // The test ballot transaction should have emitted a pair of events. Test those too
    let ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    let ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    let voteBoxDestroyedEvents: [AnyStruct] = Test.eventsOfType(voteBoxDestroyedEventType)
    let resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    let contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    /*
        This transaction also destroys a test (and empty) VoteBox using the burn function. If the VoteBox is empty, only one VoteBoxDestroyed event should be emitted. If there was a Ballot inside (which it shouldn't), than a extra BallotBurned event should be emitted as well. But the expectation is that it isn't, so I should only have one BallotBurned event being emitted from the burning of the test Ballot at the end of the transaction. Adjust the eventCounters accordingly

        NOTE: The ResourceDestroyed event is only emitted for when a NonFungibleToken.NFT resource is destroyed! Any other types of resources, such as the VoteBoothST.VoteBox DO NOT emit this event, so don't increase the event counter erroneously.
    */
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    // Validate the counters
    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // This transaction MUST FAIL if signed by any other than the contract deployer (account 'deployer') due to the lack of the VoteBoothST.Admin entitlement. 
    // This is very important because it limits the minting of new Ballots to one and only one Admin entity. Test this
    let txResult02: Test.TransactionResult = executeTransaction(
        testBallotTx,
        [account02.address],
        account01
    )

    Test.expect(txResult02, Test.beFailed())

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

    /* 
        Repeat the minting process one more time. I need 3 ballots in 3 different accounts to properly test the next 3 functions. One withdraws the ballot to a BurnBox by loading the VoteBox, the other by using a reference to the VoteBox instead and I want to leave a VoteBox with a valid Ballot to test the burning of all 3 VoteBoxes uses so far.
        All three methods should be successful, ideally
    */
    let txResult03: Test.TransactionResult = executeTransaction(
        mintBallotToAccountTx,
        [account03.address],
        deployer
    )

    Test.expect(txResult03, Test.beSucceeded())

    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // Increment the BallotMinted event counter
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    ballotMintedEvent = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

    let eventBallotId03: UInt64 = ballotMintedEvent._ballotId

    let scResult03: Test.ScriptResult = executeScript(
        getIDsSc,
        [account03.address]
    )

    storedBallotIDs = (scResult03.returnValue as! [UInt64]?)!

    Test.assertEqual(storedBallotIDs.length, 1)
    Test.assertEqual(eventBallotId03, storedBallotIDs[storedBallotIDs.length - 1])

    // Finally, trying this transaction with a signer different than the deployer should fail due to the lack of the Admin entitlement. Test this as well. Use account01 to sign the transaction instead
    let txResult04: Test.TransactionResult = executeTransaction(
        mintBallotToAccountTx,
        [account04.address],
        account01
    )

    Test.expect(txResult04, Test.beFailed())
}

/*
    Test the act of loading a VoteBox from a user, withdraw the Ballot from it and send it to burn at a later stage with a BurnBox reference
*/
access(all) fun testWithdrawBallotToBurnBoxLoad() {
    // First, try to execute the withdraw transaction with the wrong signer. This transaction must be signed by the owner of the VoteBox in question
    var txResult: Test.TransactionResult = executeTransaction(
        withdrawBallotToBurnBoxLoadTx,
        [account01.address],
        account01
    )

    // This transaction should fail because account01 does not have a BurnBox in storage. Test it
    Test.expect(txResult, Test.beFailed())

    txResult = executeTransaction(
        withdrawBallotToBurnBoxLoadTx,
        [deployer.address],
        deployer
    )

    // This one also should fail because the deployer does not have any VoteBox in the storage account
    Test.expect(txResult, Test.beFailed())

    // Before running the transaction that works, retrieve the ID of the Ballot in account01 VoteBox
    var scResult: Test.ScriptResult = executeScript(
        getIDsSc,
        [account01.address]
    )

    // Extract the script output
    let storedBallotIDs: [UInt64] = (scResult.returnValue as! [UInt64]?)!
    Test.assertEqual(storedBallotIDs.length, 1)

    let ballotToBurnId: UInt64 = storedBallotIDs[storedBallotIDs.length - 1]

    // Grab the Ballot owner as well
    scResult = executeScript(
        getBallotOwnerSc,
        [account01.address]
    )

    let ballotToBurnOwner: Address = (scResult.returnValue as! Address?)!

    txResult = executeTransaction(
        withdrawBallotToBurnBoxLoadTx,
        [deployer.address],
        account01
    )

    // This one should succeed.
    Test.expect(txResult, Test.beSucceeded())

    // The transaction should emit a BallotSetToBurn event as well. Check it and do the usual event count math
    var ballotSetToBurnEvents: [AnyStruct] = Test.eventsOfType(ballotSetToBurnEventType)

    eventNumberCount[ballotSetToBurnEventType] = eventNumberCount[ballotSetToBurnEventType]! + 1

    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)

    // Check if the Id  and owner returned in the event match the ones retrieved directly from the VoteBox
    let ballotSetToBurnEvent: VoteBoothST.BallotSetToBurn = ballotSetToBurnEvents[ballotSetToBurnEvents.length - 1] as! VoteBoothST.BallotSetToBurn

    Test.assertEqual(ballotSetToBurnEvent._ballotId, ballotToBurnId)
    Test.assertEqual(ballotSetToBurnEvent._voterAddress, ballotToBurnOwner)

    // The burning of the Ballots is going to happen a little further down the line.
}

/*
    This transaction is a bit of a repetition of the above one, but applied to account02
*/
access(all) fun testWithdrawBallotToBurnBoxRef() {
    // Start by forcing the transaction to fail like before
    var txResult: Test.TransactionResult = executeTransaction(
        withdrawBallotToBurnBoxRefTx,
        [account02.address],
        account02
    )

    // This one fails because account02 does not have a BurnBox in its storage account
    Test.expect(txResult, Test.beFailed())

    txResult = executeTransaction(
        withdrawBallotToBurnBoxRefTx,
        [deployer.address],
        deployer
    )

    // This fails because the deployer has no VoteBoxes in its storage account
    Test.expect(txResult, Test.beFailed())

    // Grab the ballotId and owner from account02 VoteBox before running the successful transaction
    var scResult: Test.ScriptResult = executeScript(
        getIDsSc,
        [account02.address]
    )

    // Extract the script output
    let storedBallotIDs: [UInt64] = (scResult.returnValue as! [UInt64]?)!
    Test.assertEqual(storedBallotIDs.length, 1)

    let ballotToBurnId: UInt64 = storedBallotIDs[storedBallotIDs.length - 1]

    // Grab the ballot owner as well
    scResult = executeScript(
        getBallotOwnerSc,
        [account02.address]
    )

    let ballotToBurnOwner: Address = (scResult.returnValue as! Address?)!

    txResult = executeTransaction(
        withdrawBallotToBurnBoxRefTx,
        [deployer.address],
        account02
    )

    Test.expect(txResult, Test.beSucceeded())

    let ballotSetToBurnEvents: [AnyStruct] = Test.eventsOfType(ballotSetToBurnEventType)

    eventNumberCount[ballotSetToBurnEventType] = eventNumberCount[ballotSetToBurnEventType]! + 1

    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)

    let ballotSetToBurnEvent: VoteBoothST.BallotSetToBurn = ballotSetToBurnEvents[ballotSetToBurnEvents.length - 1] as! VoteBoothST.BallotSetToBurn

    Test.assertEqual(ballotSetToBurnEvent._ballotId, ballotToBurnId)
    Test.assertEqual(ballotSetToBurnEvent._voterAddress, ballotToBurnOwner)
}

/*
    There should be 2 Ballots in the BurnBox at this point. Test this
*/
access(all) fun testBurnBox() {
    var txResult: Test.TransactionResult = executeTransaction(
        burnBallotFromBurnBoxTx,
        [],
        account03
    )

    // This transaction should fail because account03 does not has VoteBoothST.Admin privileges
    Test.expect(txResult, Test.beFailed())

    txResult = executeTransaction(
        burnBallotFromBurnBoxTx,
        [],
        deployer
    )

    // This one should have been successful
    Test.expect(txResult, Test.beSucceeded())

    // This transaction burns two Ballots but also emits a bunch of ContractDataInconsistency events if any are found. Check that none was emitted as well
    let ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    let resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    let contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // Adjust the event counter accordingly
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 2
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 2

    // Test if all these counts are consistent
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)
}

/*
    This test destroys all VoteBoxes used so far, i.e., for account01, account02 and account03. The last one (account03) still has a valid Ballot in it (I left it there on purpose), so check that the relevant events are emitted as well
*/
access(all) fun testDestroyVoteBox() {
    // Destroy the VoteBoxes for account01 and account02 and check that no BallotBurned events were emitted. Only the VoteBoxDestroyed event should be emitted twice
    var txResult: Test.TransactionResult = executeTransaction(
        destroyVoteBoxTx,
        [],
        deployer
    )

    // This one should fail because the deployer does not has a VoteBox
    Test.expect(txResult, Test.beFailed())

    txResult = executeTransaction(
        destroyVoteBoxTx,
        [],
        account01
    )

    // This one should succeed and emit one VoteBoxDestroyed event and nothing else.
    Test.expect(txResult, Test.beSucceeded())

    // Validate the events. VoteBoxes are NOT NonFungibleTokens.NFTs, so they should NOT emit the ResourceDestroyed event. Test it
    var voteBoxDestroyedEvents: [AnyStruct] = Test.eventsOfType(voteBoxDestroyedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // Only the voteBoxDestroyed counter should have been increased over the existing value
    eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1

    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Test that, in this case, the VoteBoxDestroyed event has 0 Ballots destroyed and nil as ballotId since the VoteBox should be empty
    var voteBoxDestroyedEvent: VoteBoothST.VoteBoxDestroyed = voteBoxDestroyedEvents[voteBoxDestroyedEvents.length - 1] as! VoteBoothST.VoteBoxDestroyed

    Test.assertEqual(voteBoxDestroyedEvent._ballotsInBox, 0)
    Test.assertEqual(voteBoxDestroyedEvent._ballotId, nil)

    // Repeat this for account02. Nothing should change from the previous case
    txResult = executeTransaction(
        destroyVoteBoxTx,
        [],
        account02
    )

    Test.expect(txResult, Test.beSucceeded())

    // Update the event structures
    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1

    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    voteBoxDestroyedEvent = voteBoxDestroyedEvents[voteBoxDestroyedEvents.length - 1] as! VoteBoothST.VoteBoxDestroyed

    Test.assertEqual(voteBoxDestroyedEvent._ballotsInBox, 0)
    Test.assertEqual(voteBoxDestroyedEvent._ballotId, nil)

    // Finally, destroy the VoteBox in account03. This one still has a valid Ballot in it, so deal with accordingly!
    // First, extract the ballotId and ballotOwner from the VoteBox in account03
    var scResult: Test.ScriptResult = executeScript(
        getIDsSc,
        [account03.address]
    )

    let storedBallotIds: [UInt64] = (scResult.returnValue as! [UInt64]?)!

    let ballotToBurnId: UInt64 = storedBallotIds[storedBallotIds.length - 1]

    scResult = executeScript(
        getBallotOwnerSc,
        [account03.address]
    )

    let ballotToBurnOwner: Address = (scResult.returnValue as! Address?)!

    txResult = executeTransaction(
        destroyVoteBoxTx,
        [],
        account03
    )

    Test.expect(txResult, Test.beSucceeded())

    // Update the event structures taking into account the Ballot that was destroyed
    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // I should have an increment in VoteBoxDestroyed, BallotBurned and resourceDestroyed events (because a Ballot IS a NonFungibleToken.NFT)
    eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    voteBoxDestroyedEvent = voteBoxDestroyedEvents[voteBoxDestroyedEvents.length - 1] as! VoteBoothST.VoteBoxDestroyed

    // In this case, the event should have 1 ballotsInBox and a non-nil ballotId equal to the ballotId retrieved above
    Test.assertEqual(voteBoxDestroyedEvent._ballotsInBox, 1)
    Test.assertEqual(voteBoxDestroyedEvent._ballotId!, ballotToBurnId)

    let ballotBurnedEvent: VoteBoothST.BallotBurned = ballotBurnedEvents[ballotBurnedEvents.length - 1] as! VoteBoothST.BallotBurned

    Test.assertEqual(ballotBurnedEvent._ballotId!, ballotToBurnId)
    Test.assertEqual(ballotBurnedEvent._voterAddress!, ballotToBurnOwner)
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
        
        if (VoteBoothST.printLogs) {
            log(
                "Successfully created a VoteBox for account "
                .concat(account.address.toString())
            )
        }
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

    if (VoteBoothST.printLogs) {
        log(
            "Successfully minted one Ballot for accounts "
        )

        for account in accounts {
            log(
                account.address.toString()
            )
        }
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
    TODO: Review this
*/
access(all) fun _testBurnBallots() {
    // TODO: Complete this one. This test simply follows the loop logic so far, so this one does more of the same but for all accounts in a loop. Just follow the logic so far
}

// TODO: Modify Ballots (Vote)
// TODO: Multiple Vote Casting
// TODO: Eligibility Module
// TODO: Tally Contract
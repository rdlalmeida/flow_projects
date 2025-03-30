import Test
import BlockchainHelpers
import "VoteBoothST"
import "NonFungibleToken"

access(all) let electionName: String = "World's best dog ever!"
access(all) let electionSymbol: String = "WBDE"
access(all) let electionLocation: String = "Campinho"
access(all) let electionBallot: String = "Who was the best dog this summer? Options: \n1 - Eddie, \n2 - Argus, \n3 - Both, \n4 - None"
access(all) let electionOptions: Int = 4

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
    /*
        NOTE: The deployContract bellow respects the one where I can set a [UInt64] as contract constructor argument. I can do this with no problems in this test file, but I cannot deploy a contract with the emulator as such. I'm unable to use the flow.json file to define this argument (all the other ones are OK, but by some reason, [UInt64] is a no, no!). Check a comment at the contract constructor for more details.
        As such, just to keep moving forward with this, I've opened a ticket with Flow itself and I'm hardcoding the election options in the contract so that I can remove this argument from the constructor list. The electionOptions argument was set as a Int so that I can move forward and the contract creates a [Int] internally between 1 and the electionOptions value provided
    */
    let err: Test.Error? = Test.deployContract(
        name: "VoteBoothST",
        path: "../contracts/VoteBoothST.cdc",
        arguments: [electionName, electionSymbol, electionBallot, electionLocation, electionOptions, printLogs]
    )

    Test.expect(err, Test.beNil())

    // Test that the BallotBox event was emitted
    var ballotBoxCreatedEvents: [AnyStruct] = Test.eventsOfType(ballotBoxCreatedEventType)

    // Test that one and only one event of this type was emitted
    eventNumberCount[ballotBoxCreatedEventType] = eventNumberCount[ballotBoxCreatedEventType]! + 1
    Test.assertEqual(ballotBoxCreatedEvents.length, eventNumberCount[ballotBoxCreatedEventType]!)

    // Test that the address in the event matched the deployer and none else
    let ballotBoxCreatedEvent: VoteBoothST.BallotBoxCreated = ballotBoxCreatedEvents[0] as! VoteBoothST.BallotBoxCreated

    Test.assertEqual(deployer.address, ballotBoxCreatedEvent._accountAddress)

    // Do a simple loop printing the addresses for each account so that I know, when a problem occurs, which one is the offending one
    // Start with the deployer
    log(
        "Deployer account address = "
        .concat(deployer.address.toString())
    )

    // And now for the remaining accounts
    for index, account in accounts{
        log(
            "Account 0"
            .concat((index + 1).toString())
            .concat(" address = ")
            .concat(account.address.toString())
        )
    }
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
    let contractOptions: [Int] = VoteBoothST.getElectionOptions()

    log(
        "Range of election Options in the contract: "
    )
    log(
        contractOptions
    )

    let range: InclusiveRange<Int> = InclusiveRange(1, electionOptions, step: 1)
    var expectedElectionOptions: [Int] = []

    for element in range {
        expectedElectionOptions.append(element)
    }

    for option in expectedElectionOptions {
        Test.assertEqual(contractOptions.contains(option), true)
    }
}
access(all) fun testGetTotalBallotsMinted() {
    Test.assertEqual(VoteBoothST.getTotalBallotsMinted(), 0 as (UInt64))
}
access(all) fun testGetTotalBallotsSubmitted() {
    Test.assertEqual(VoteBoothST.getTotalBallotsSubmitted(), 0 as (UInt64))
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

access(all) fun testOwnerControl() {
    // Next transaction mints and burns 2 ballots. Check if the totalBallotsMinted keeps its consistency
    let totalBallotsMintedBefore: UInt64 = VoteBoothST.getTotalBallotsMinted()

    var txResult: Test.TransactionResult = executeTransaction(
        testOwnerControlTx,
        [account01.address, account02.address],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // This value should have been maintained after all the things
    Test.assertEqual(totalBallotsMintedBefore, VoteBoothST.getTotalBallotsMinted())

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

    // Try the same transaction again but with a normal account as signer. This should fail because non-deployer accounts do not have access to the OwnerControl resource
    txResult = executeTransaction(
        testOwnerControlTx,
        [account01.address, account02.address],
        account03
    )

    Test.expect(txResult, Test.beFailed())

    // Test also that the totalBallotsMinted was not modified
    Test.assertEqual(totalBallotsMintedBefore, VoteBoothST.getTotalBallotsMinted())

    // No need to check the events, since if there any error (i.e., an unexpected event being emitted) the next tests should blow up because I'm constantly verifying the event counters.
}

access(all) fun testMinterLoading() {
    // Run the corresponding transaction
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotPrinterTx,
        [],
        deployer
    )

    // This transaction is expected to fail in all circumstances! I've set this resource to be usable only through authorized references, for obvious security reasons. Check the transaction text for a detailed explanation.
    Test.expect(txResult01, Test.beFailed())
}

access(all) fun testMinterReference() {
    // The next transaction mints and burns one test Ballot. Check that the totalBallotsMinted maintains consistency
    let totalBallotsMintedBefore: UInt64 = VoteBoothST.getTotalBallotsMinted()

    // This transaction runs a similar function but using an authorized reference instead of loading  the resource, as it is supposed to be used
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotPrinterAdminTx,
        [account01.address],
        deployer
    )

    Test.expect(txResult01, Test.beSucceeded())

    // Validate that the total Ballots minted remained unchanged (0)
    Test.assertEqual(totalBallotsMintedBefore, VoteBoothST.getTotalBallotsMinted())

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

    // Check that the number of total Ballots minted didn't changed
    Test.assertEqual(totalBallotsMintedBefore, VoteBoothST.getTotalBallotsMinted())

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
    // The next transaction mints and burns a Ballot for testing purposes. Save the current totalBallotsMinted and verify that it is maintained after this transaction.
    let totalBallotsMintedBefore: UInt64 = VoteBoothST.getTotalBallotsMinted()

    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotBoxLoadTx,
        [account01.address],
        deployer
    )

    // The expectation is for this transaction to run if signed by the deployer, but not if anyone else signs it instead
    Test.expect(txResult01, Test.beSucceeded())

    // Check if the totalBallotsMinted was maintained
    Test.assertEqual(totalBallotsMintedBefore, VoteBoothST.getTotalBallotsMinted())

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

    // Test that this transaction did not affected the totalBallotsMinted
    Test.assertEqual(totalBallotsMintedBefore, VoteBoothST.getTotalBallotsMinted())

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
    let totalBallotsMintedBefore: UInt64 = VoteBoothST.getTotalBallotsMinted()

    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotBoxRefTx,
        [account02.address],
        deployer
    )

    // As before, the expectation is that this transaction works with the deployer but with no one else
    Test.expect(txResult01, Test.beSucceeded())

    Test.assertEqual(totalBallotsMintedBefore, VoteBoothST.getTotalBallotsMinted())

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
    // As usual, this transaction mints and burns one test Ballot, so the total Ballots minted should remain the same
    let totalBallotsMintedBefore: UInt64 = VoteBoothST.getTotalBallotsMinted()

    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotTx,
        [account03.address],
        deployer
    )

    Test.expect(txResult01, Test.beSucceeded())

    Test.assertEqual(totalBallotsMintedBefore, VoteBoothST.getTotalBallotsMinted())

    // The test ballot transaction should have emitted a pair of events. Test those too
    let ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    let ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    let voteBoxDestroyedEvents: [AnyStruct] = Test.eventsOfType(voteBoxDestroyedEventType)
    let resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    let contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    /*
        This transaction also destroys a test (and empty) VoteBox using the burn function. If the VoteBox is empty, only one VoteBoxDestroyed event should be emitted. If there was a Ballot inside (which it shouldn't), than a extra BallotBurned event should be emitted as well, because I'm using a ballotPrinterAdmin burn function to do it. But the expectation is that it isn't, so I should only have one BallotBurned event being emitted from the burning of the test Ballot at the end of the transaction. Adjust the eventCounters accordingly

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

access(all) fun testToTalBallotsMinted2() {
    let finalTotalBallotsMinted: UInt64 = VoteBoothST.getTotalBallotsMinted()

    log(
        "Final total ballots minted: "
        .concat(finalTotalBallotsMinted.toString())
    )
}

// TODO: Continue from here with the total Ballots Minted logic. Use script 05 to get the totalBallotsMinted instead of calling the function itself. Maybe it works...

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
    var ballotSetToBurnEvents: [AnyStruct] = Test.eventsOfType(ballotSetToBurnEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // Only the voteBoxDestroyed counter should have been increased over the existing value
    eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1

    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)
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
    ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1

    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)
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

    // This one triggers the Ballot still stored in the VoteBox to be sent to the deployer's BurnBox (does not burn the actual Ballot, yet)
    txResult = executeTransaction(
        destroyVoteBoxTx,
        [],
        account03
    )

    Test.expect(txResult, Test.beSucceeded())

    // Update the event structures taking into account that when a VoteBox is destroyed while a valid Ballot is still in it, the Ballot is sent to the deployer's BurnBox instead. Test if the relevant event was emitted
    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // I should have an increment in VoteBoxDestroyed and BallotSetToBurn and nothing else
    eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1
    eventNumberCount[ballotSetToBurnEventType] = eventNumberCount[ballotSetToBurnEventType]! + 1


    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    voteBoxDestroyedEvent = voteBoxDestroyedEvents[voteBoxDestroyedEvents.length - 1] as! VoteBoothST.VoteBoxDestroyed

    // Grab the proper BallotSetToBurn event as well. The arguments in this one should match the ones above
    let ballotSetToBurnEvent: VoteBoothST.BallotSetToBurn = ballotSetToBurnEvents[ballotSetToBurnEvents.length - 1] as! VoteBoothST.BallotSetToBurn

    // In this case, the event should have 1 ballotsInBox and a non-nil ballotId equal to the ballotId retrieved above
    Test.assertEqual(voteBoxDestroyedEvent._ballotsInBox, 1)
    Test.assertEqual(voteBoxDestroyedEvent._ballotId!, ballotToBurnId)

    Test.assertEqual(ballotSetToBurnEvent._ballotId, ballotToBurnId)
    Test.assertEqual(ballotSetToBurnEvent._voterAddress, ballotToBurnOwner)

    // I should have 1 Ballot in the contract deployer's BurnBox. Test this and set it to burn as in the previous test, while doing the usual checks and such

    txResult = executeTransaction(
        burnBallotFromBurnBoxTx,
        [],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // Check all the events so far
    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // Only the BallotBurned and ResourceDestroyed events should have been incremented by 1 (because, unlike the VoteBox, a Ballot IS a NonFungibleToken.NFT, therefore it automatically emits this event)
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Validate the remaining parameters
    let ballotBurnedEvent: VoteBoothST.BallotBurned = ballotBurnedEvents[ballotBurnedEvents.length - 1] as! VoteBoothST.BallotBurned

    Test.assertEqual(ballotBurnedEvent._ballotId!, ballotToBurnId)
    Test.assertEqual(ballotBurnedEvent._voterAddress!, ballotToBurnOwner)
}


/*
    This test is simply a generalisation for the same test using the singular tense. All this does is to run the testCreateVoteBox but using a for cycle to automate stuff.

    NOTE: This function and the next one are exclusive to the non-looped versions of the same functions
    IMPORTANT: only one pair of these function should be "active", i.e., the name of the test function starts with "test". I'm using an underscore (_) to before the test part to deactivate the function
*/
access(all) fun testCreateVoteBoxes() {
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
access(all) fun testBallotMintingToVoteBoxes() {
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
    This particular test burns the Ballots from the VoteBoxes for the first 3 accounts.
*/
access(all) fun testWithdrawBallotsToBurnBox() {
    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil

    var ballotSetToBurnEvents: [AnyStruct] = []

    var ballotToBurnId: UInt64? = nil
    var ballotToBurnOwner: Address? = nil

    var ballotSetToBurnEvent: VoteBoothST.BallotSetToBurn? = nil

    var ballotsToBurnIds: [UInt64] = []
    var ballotsToBurnOwners: [Address] = []

    // Create a subset of the accounts array for this purpose (only with the first 3 accounts)
    let burnableBallotAccounts: [Test.TestAccount] = [account01, account02, account03]

    // Before moving to the first loop, check that trying to withdraw a Ballot and deposit it to a BurnBox does not happens (transaction fails)
    // for the deployer account since the deployer does not have a VoteBox nor a Ballot anywhere

    txResult = executeTransaction(
        withdrawBallotToBurnBoxRefTx,
        [deployer.address],
        deployer
    )

    Test.expect(txResult, Test.beFailed())

    for account in burnableBallotAccounts {
        // The fist attempt is made to fail on purpose. None of the accounts in the array has a BurnBox in their accounts, only the deployer has those.
        txResult = executeTransaction(
            withdrawBallotToBurnBoxRefTx,
            [account.address],
            account
        )

        Test.expect(txResult, Test.beFailed())

        // Grab the Ballot's data for later comparison
        scResult = executeScript(
            getIDsSc,
            [account.address]
        )

        ballotToBurnId = (scResult!.returnValue as! [UInt64]?)![0]

        scResult = executeScript(
            getBallotOwnerSc,
            [account.address]
        )

        ballotToBurnOwner = (scResult!.returnValue as! Address?)!

        // Now for the real one
        txResult = executeTransaction(
            withdrawBallotToBurnBoxRefTx,
            [deployer.address],
            account
        )

        Test.expect(txResult, Test.beSucceeded())

        // Capture and validate events
        ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)

        // The event number should have been increased by one
        eventNumberCount[ballotSetToBurnEventType] = eventNumberCount[ballotSetToBurnEventType]! + 1

        Test.assertEqual(eventNumberCount[ballotSetToBurnEventType]!, ballotSetToBurnEvents.length)

        // Grab the last event of the array and validate it
        ballotSetToBurnEvent = ballotSetToBurnEvents[ballotSetToBurnEvents.length - 1] as! VoteBoothST.BallotSetToBurn

        Test.assertEqual(ballotSetToBurnEvent!._ballotId, ballotToBurnId!)
        Test.assertEqual(ballotSetToBurnEvent!._voterAddress, ballotToBurnOwner!)

        // Before finishing this cycle, add the ballotIds and ballotOwners to the respective arrays for future comparison
        ballotsToBurnIds.append(ballotToBurnId!)
        ballotsToBurnOwners.append(ballotToBurnOwner!)
    }

    // Check that the ballotsToBurnIds and ballotsToBurnOwners match the length of the account array used
    Test.assertEqual(ballotsToBurnIds.length, burnableBallotAccounts.length)
    Test.assertEqual(ballotsToBurnOwners.length, burnableBallotAccounts.length)

    // Finish this by setting the BurnBox to burn all existing Ballots. The BallotBurned events should match the ids and owners captured thus far
    txResult = executeTransaction(
        burnBallotFromBurnBoxTx,
        [],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // I should have 3 more BallotBurned and ResourceDestroyed events and nothing more because, again, Ballots are NonFungibleToken.NFTs
    let ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    let resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    let contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // Adjust the event counter
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + burnableBallotAccounts.length
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + burnableBallotAccounts.length

    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    var ballotBurnedEvent: VoteBoothST.BallotBurned? = nil

    // Check that the BallotBurned events match
    for index, ballotId in ballotsToBurnIds {
        // Grab the BallotBurned event with index. Because of the unknown length of the event set, I need to be creative to get the proper event from the array
        ballotBurnedEvent = ballotBurnedEvents[ballotBurnedEvents.length - ballotsToBurnIds.length + index] as! VoteBoothST.BallotBurned

        // Test if the array of ballotsToBurnIds and ballotsToBurnOwners contain the arguments returned in the event. I cannot rely on the indexes because, by some reason, the events are not set in the array in order, so I need to use the "contains" function instead
        Test.assertEqual(ballotsToBurnIds.contains(ballotBurnedEvent!._ballotId!), true)
        Test.assertEqual(ballotsToBurnOwners.contains(ballotBurnedEvent!._voterAddress!), true)
    }
}

/*
    This function completes this cycle by destroying all the VoteBoxes, which implies that the Ballots in the remaining 2 accounts that were not burned in the previous function are going to set to the deployer's BurnBox, to be destroyed after the cycles are done
*/
access(all) fun testDestroyVoteBoxes() {
    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil

    var ballotBurnedEvents: [AnyStruct] = []
    var ballotSetToBurnEvents: [AnyStruct] = []
    var voteBoxDestroyedEvents: [AnyStruct] = []
    var resourceDestroyedEvents: [AnyStruct] = []
    var contractDataInconsistentEvents: [AnyStruct] = []

    var ballotBurnedEvent: VoteBoothST.BallotBurned? = nil
    var ballotSetToBurnEvent: VoteBoothST.BallotSetToBurn? = nil
    var voteBoxDestroyedEvent: VoteBoothST.VoteBoxDestroyed? = nil

    var ballotToBurnId: UInt64? = nil
    var ballotToBurnOwner: Address? = nil

    var ballotsToBurnIds: [UInt64] = []
    var ballotsToBurnOwners: [Address] = []

    // Set the remaining 2 accounts for this process
    let burnableVoteBoxesAccounts: [Test.TestAccount] = [account04, account05]

    // First, just to be sure, try to destroy a VoteBox from the deployer account. This should fail because the deployer has none
    txResult = executeTransaction(
        destroyVoteBoxTx,
        [],
        deployer
    )

    Test.expect(txResult, Test.beFailed())

    // Now for the real deal
    for account in burnableVoteBoxesAccounts {
        // First, capture the ballotId and ballotOwner to the dedicated arrays for future comparison
        scResult = executeScript(
            getIDsSc,
            [account.address]
        )

        ballotToBurnId = (scResult!.returnValue as! [UInt64]?)![0]
        ballotsToBurnIds.append(ballotToBurnId!)

        scResult = executeScript(
            getBallotOwnerSc,
            [account.address]
        )

        ballotToBurnOwner = (scResult!.returnValue as! Address?)
        ballotsToBurnOwners.append(ballotToBurnOwner!)

        txResult = executeTransaction(
            destroyVoteBoxTx,
            [],
            account
        )

        Test.expect(txResult, Test.beSucceeded())

        // Check the event structures as usual
        voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
        ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
        ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)
        resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
        contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

        // At this stage, only the VoteBoxDestroyed and BallotSetToBurn events should have been incremented by 1. Reflect this on the event counters
        eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1
        eventNumberCount[ballotSetToBurnEventType] = eventNumberCount[ballotSetToBurnEventType]! + 1

        Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
        Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
        Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)
        Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
        Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

        // Capture the new events and validate that the arguments match
        voteBoxDestroyedEvent = voteBoxDestroyedEvents[voteBoxDestroyedEvents.length - 1] as! VoteBoothST.VoteBoxDestroyed

        // VoteBoxDestroyed events should have 1 ballotsInBox and the ballotId should match with the one retrieved with the script before
        Test.assertEqual(voteBoxDestroyedEvent!._ballotsInBox, 1)
        Test.assertEqual(voteBoxDestroyedEvent!._ballotId!, ballotToBurnId!)

        // Same for the BallotSetToBurn
        ballotSetToBurnEvent = ballotSetToBurnEvents[ballotSetToBurnEvents.length - 1] as! VoteBoothST.BallotSetToBurn

        Test.assertEqual(ballotSetToBurnEvent!._ballotId, ballotToBurnId!)
        Test.assertEqual(ballotSetToBurnEvent!._voterAddress, ballotToBurnOwner!)
    }

    // If everything checks out, move to burn all ballots currently in the BurnBox
    txResult = executeTransaction(
        burnBallotFromBurnBoxTx,
        [],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // Update the event structures
    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    //  The BallotBurned and ResourceDestroyed events should have been increase by the number of accounts in question
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + burnableVoteBoxesAccounts.length
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + burnableVoteBoxesAccounts.length

    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Capture and validate that the last BallotBurned event arguments match the ids and owners captured before
    for index, ballotId in ballotsToBurnIds {
        ballotBurnedEvent = ballotBurnedEvents[ballotBurnedEvents.length - 1 - index] as! VoteBoothST.BallotBurned

        Test.assertEqual(ballotsToBurnIds.contains(ballotBurnedEvent!._ballotId!), true)
        Test.assertEqual(ballotsToBurnOwners.contains(ballotBurnedEvent!._voterAddress!), true)
    }
}
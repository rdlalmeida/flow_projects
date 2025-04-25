import Test
import BlockchainHelpers
import "VoteBoothST"
import "NonFungibleToken"

access(all) let electionName: String = "World's best dog ever!"
access(all) let electionSymbol: String = "WBDE"
access(all) let electionLocation: String = "Campinho"
access(all) let electionBallot: String = "Who was the best dog this summer? Options: \n1 - Eddie, \n2 - Argus, \n3 - Both, \n4 - None"
access(all) let electionOptions: [UInt8] = [1, 2, 3, 4] 

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
    {<ACCOUNT_ADDRESS>: <BALLOT_ID>}
*/
access(all) var ballots: {Address: UInt64} = {}

access(all) let addresses: [Address] = [account01.address, account02.address, account03.address, account04.address, account05.address]

// TRANSACTIONS
access(all) let testOwnerControlTx: String = "../transactions/01_test_owner_control.cdc"
access(all) let testBallotPrinterTx: String = "../transactions/02_test_ballot_printer_admin.cdc"
access(all) let testBallotPrinterAdminTx: String = "../transactions/03_test_ballot_printer_admin_reference.cdc"
access(all) let testBallotBoxTx: String = "../transactions/04_test_ballot_box.cdc"
access(all) let voteBoxCreationTx: String = "../transactions/05_create_vote_box.cdc"
access(all) let testBallotTx: String = "../transactions/06_test_ballot.cdc"
access(all) let mintBallotToAccountTx: String = "../transactions/07_mint_ballot_to_account.cdc"
access(all) let mintBallotsToAccountsTx: String = "../transactions/08_mint_ballots_to_accounts.cdc"
access(all) let submitBallotToBallotBoxTx: String = "../transactions/09_submit_ballot_to_ballot_box.cdc"
access(all) let burnBallotFromBurnBoxTx: String = "../transactions/10_burn_ballots_from_burn_box.cdc"
access(all) let destroyVoteBoxTx: String = "../transactions/11_destroy_vote_box.cdc"

// SCRIPTS
access(all) let testVoteBoxSc: String = "../scripts/01_test_vote_box.cdc"
access(all) let getVoteOptionsSc: String = "../scripts/02_get_vote_option.cdc"
access(all) let getBallotIdSc: String = "../scripts/03_get_ballot_id.cdc"
access(all) let getBallotOwnerSc: String = "../scripts/04_get_ballot_owner.cdc"
access(all) let getTotalBallotsMintedSc: String = "../scripts/05_get_total_ballots_minted.cdc"
access(all) let getTotalBallotsSubmittedSc: String = "../scripts/06_get_total_ballots_submitted.cdc"
access(all) let getHowManyBallotsToBurnSc: String = "../scripts/08_get_how_many_ballots_to_burn.cdc"
access(all) let getOwnerControlBallotIdSc: String = "../scripts/09_get_owner_control_ballot_id.cdc"
access(all) let getOwnerControlOwnerSc: String = "../scripts/10_get_owner_control_owner.cdc"

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
access(all) let ballotRevokedEventType: Type = Type<VoteBoothST.BallotRevoked>()
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
    ballotRevokedEventType: 0,
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
    let contractOptions: [UInt8] = VoteBoothST.getElectionOptions()

    if (printLogs) {
        log(
            "Range of election Options in the contract: "
        )
        log(
            contractOptions
        )
    }

    for option in electionOptions {
        Test.assertEqual(contractOptions.contains(option), true)
    }
}

access(all) fun testGetTotalBallotsMinted() {
    let scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    Test.assertEqual((scResult.returnValue as! UInt64), 0 as (UInt64))
}

access(all) fun testGetTotalBallotsSubmitted() {
    let scResult: Test.ScriptResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    Test.assertEqual((scResult.returnValue as! UInt64), 0 as (UInt64))
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
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalBallotsMinted: UInt64 = (scResult.returnValue as! UInt64)

    var txResult: Test.TransactionResult = executeTransaction(
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

    // Try the same transaction again but with a normal account as signer. This should fail because non-deployer accounts do not have access to the OwnerControl resource
    txResult = executeTransaction(
        testOwnerControlTx,
        [account01.address, account02.address],
        account03
    )

    Test.expect(txResult, Test.beFailed())

    // Test also that the totalBallotsMinted was not modified
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalBallotsMinted: UInt64 = (scResult.returnValue as! UInt64)

    // This value should have been maintained after all the things
    Test.assertEqual(initialTotalBallotsMinted, finalTotalBallotsMinted)

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
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    // This transaction runs a similar function but using an authorized reference instead of loading  the resource, as it is supposed to be used
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

    // Finish by making sure that the total number of minted ballots is still the same as in the beginning
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    Test.assertEqual(initialTotalBallotsMinted, finalTotalBallotsMinted)
}


access(all) fun testBallotBox() {
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotBoxTx,
        [account02.address],
        deployer
    )

    // As before, the expectation is that this transaction works with the deployer but with no one else
    Test.expect(txResult01, Test.beSucceeded())

    // Check the usual events
    var ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    // The Ballot submitted with the test ends up being revoked, as a way to not having it hanging around in any account. As such, take this into account as well
    var ballotRevokedEvents: [AnyStruct] = Test.eventsOfType(ballotRevokedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // The successful transaction should increment the successful events number by one
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    // I should have one BallotRevoked event as well
    eventNumberCount[ballotRevokedEventType] = eventNumberCount[ballotRevokedEventType]! + 1

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(ballotRevokedEvents.length, eventNumberCount[ballotRevokedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Repeat the transaction but with the wrong signer. Everything must fail
    let txResult02: Test.TransactionResult = executeTransaction(
        testBallotBoxTx,
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

    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    // Validate that the total number of ballots minted was maintained
    Test.assertEqual(initialTotalBallotsMinted, finalTotalBallotsMinted)
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
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotTx,
        [account03.address],
        deployer
    )

    Test.expect(txResult01, Test.beSucceeded())

    // The test ballot transaction should have emitted a pair of events. Test those too
    let ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    let ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    let resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    let contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    /*
        This transaction also destroys a test (and empty) VoteBox using the burn function. If the VoteBox is empty, only one VoteBoxDestroyed event should be emitted. If there was a Ballot inside (which it shouldn't), than a extra BallotBurned event should be emitted as well, because I'm using a ballotPrinterAdmin burn function to do it. But the expectation is that it isn't, so I should only have one BallotBurned event being emitted from the burning of the test Ballot at the end of the transaction. Adjust the eventCounters accordingly

        NOTE: The ResourceDestroyed event is only emitted for when a NonFungibleToken.NFT resource is destroyed! Any other types of resources, such as the VoteBoothST.VoteBox DO NOT emit this event, so don't increase the event counter erroneously.
    */
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
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

    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    Test.assertEqual(initialTotalBallotsMinted, finalTotalBallotsMinted)

}

access(all) fun testBallotMintingToVoteBox() {
    // NOTE: This test assumes that the "testCreateVoteBox" has run successfully first, i.e., account01 and account02 have a valid VoteBox in their storage area and a public capability published.
    var scResult: Test.ScriptResult? = nil

    // Grab the number of current ballots minted using the script
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalBallotsMinted: UInt64 = (scResult!.returnValue as! UInt64)

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

    // Grab the Ballot Id using the getBallotIds script
    let scResult01: Test.ScriptResult = executeScript(
        getBallotIdSc,
        [account01.address]
    )

    // Extract the script results
    var storedBallotId: UInt64? = scResult01.returnValue as! UInt64?

    // There should be one and only one ballot in account01's VoteBox
    Test.assert(storedBallotId != nil, message: "There's no Ballot stored in ".concat(account01.address.toString()).concat(" account!"))

    // Extract and compare the two ballot ids
    Test.assertEqual(eventBallotId01, storedBallotId!)

    // Populate the ballots struct
    ballots[account01.address] = storedBallotId

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
        getBallotIdSc,
        [account02.address]
    )

    storedBallotId = scResult02.returnValue as! UInt64?

    Test.assert(storedBallotId != nil, message: "There are no Ballots in account ".concat(account02.address.toString()))
    Test.assertEqual(eventBallotId02, storedBallotId!)

    ballots[account02.address] = storedBallotId

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
        getBallotIdSc,
        [account03.address]
    )

    storedBallotId = scResult03.returnValue as! UInt64?

    Test.assert(storedBallotId != nil, message: "There are no Ballots stored in account ".concat(account03.address.toString()))
    Test.assertEqual(eventBallotId03, storedBallotId!)

    ballots[account03.address] = storedBallotId

    // Finally, trying this transaction with a signer different than the deployer should fail due to the lack of the Admin entitlement. Test this as well. Use account01 to sign the transaction instead
    let txResult04: Test.TransactionResult = executeTransaction(
        mintBallotToAccountTx,
        [account04.address],
        account01
    )

    Test.expect(txResult04, Test.beFailed())

    // Before finishing, grab the total ballots minted again and check that it is +3
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalBallotsMinted: UInt64 = (scResult!.returnValue as! UInt64)

    Test.assertEqual(initialTotalBallotsMinted + 3, finalTotalBallotsMinted)
}

access(all) fun testInvalidBallotSubmission() {
    // Capture the contract's totalMintedBallots and totalSubmittedBallots to make sure that none of these parameters change during this function
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalMintedBallots: UInt64 = scResult.returnValue as! UInt64

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    let initialTotalSubmittedBallots: UInt64 = scResult.returnValue as! UInt64

    // Start by trying to submit a Ballot from an account without one yet (account04) at this point
    var txResult: Test.TransactionResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [1 as UInt8],
        account04
    )

    // This one should fail because account04 has a VoteBox but it is still empty at this point
    Test.expect(txResult, Test.beFailed())

    txResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [123 as UInt8],
        account01
    )

    // This one fails as well because I'm providing it with an invalid option
    Test.expect(txResult, Test.beFailed())

    // Grab the totals again and make sure they haven't changed
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalMintedBallots: UInt64 = scResult.returnValue as! UInt64

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    let finalTotalSubmittedBallots: UInt64 = scResult.returnValue as! UInt64

    Test.assertEqual(initialTotalMintedBallots, finalTotalMintedBallots)
    Test.assertEqual(initialTotalSubmittedBallots, finalTotalSubmittedBallots)
}

access(all) fun testValidBallotSubmission() {
    // As usual, start by grabbing the total ballots of each kind at this time
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalMintedBallots: UInt64 = scResult.returnValue as! UInt64

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    let initialTotalSubmittedBallots: UInt64 = scResult.returnValue as! UInt64

    // Grab account01's Ballot parameters to validate the events later on
    scResult = executeScript(
        getBallotIdSc,
        [account01.address]
    )

    let storedBallotId: UInt64? = scResult.returnValue as! UInt64?

    if (storedBallotId == nil) {
        panic(
            "The VoteBox for account "
            .concat(account01.address.toString())
            .concat(" has no valid Ballots in it yet!")
        )
    }
    scResult = executeScript(
        getBallotOwnerSc,
        [account01.address]
    )

    let storedBallotOwner: Address? = scResult.returnValue as! Address?

    // Get the Ballot data from the owner control and check that it is consistent with the data retrieved from the VoteBox
    scResult = executeScript(
        getOwnerControlBallotIdSc,
        [deployer.address, account01.address]
    )

    var ownerControlBallotId: UInt64? = scResult.returnValue as! UInt64?

    // Check first that a valid ballotId was returned (and not a nil)
    Test.assert(ownerControlBallotId != nil)

    // And then check that it matches the expected one
    Test.assertEqual(ownerControlBallotId!, storedBallotId!)

    // Repeat for the Ballot owner
    scResult = executeScript(
        getOwnerControlOwnerSc,
        [deployer.address, storedBallotId!]
    )

    var ownerControlOwner: Address? = scResult.returnValue as! Address?

    Test.assert(ownerControlOwner != nil)
    Test.assertEqual(ownerControlOwner!, storedBallotOwner!)

    // All good. Submit the Ballot in account01 with a valid option
    var txResult: Test.TransactionResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [1 as UInt8],
        account01
    )

    Test.expect(txResult, Test.beSucceeded())

    // The number of minted ballots should have been decreased by the same number of incremented submitted ballots
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalMintedBallots: UInt64 = scResult.returnValue as! UInt64

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    let finalTotalSubmittedBallots: UInt64 = scResult.returnValue as! UInt64

    // A valid Ballot submission only increases the total ballots submitted. The minted number remains the same
    Test.assertEqual(initialTotalMintedBallots, finalTotalMintedBallots)
    Test.assertEqual(initialTotalSubmittedBallots + 1, finalTotalSubmittedBallots)

    // Grab the ballotId and owner from the OwnerControl resource again. Now I expect that both should be nil after the submission
    scResult = executeScript(
        getOwnerControlBallotIdSc,
        [deployer.address, account01.address]
    )

    ownerControlBallotId = scResult.returnValue as! UInt64?

    Test.assertEqual(ownerControlBallotId, nil)

    scResult = executeScript(
        getOwnerControlOwnerSc,
        [deployer.address, storedBallotId]
    )

    ownerControlOwner = scResult.returnValue as! Address?

    Test.assertEqual(ownerControlOwner, nil)

    // After a successful submission, there should be one more event in the ballot submitted events. The contract data inconsistent ones should remain unchanged
    eventNumberCount[ballotSubmittedEventType] = eventNumberCount[ballotSubmittedEventType]! + 1

    // Validate the rest
    // Grab the events for the events that should be emitted and the ones that should not
    var ballotSubmittedEvents: [AnyStruct] = Test.eventsOfType(ballotSubmittedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    Test.assertEqual(eventNumberCount[ballotSubmittedEventType]!, ballotSubmittedEvents.length)
    Test.assertEqual(eventNumberCount[contractDataInconsistentEventType]!, contractDataInconsistentEvents.length)

    // Grab the last event from the BallotSubmitted set and validate the arguments against the ones grabbed from the VoteBox
    let ballotSubmittedEvent: VoteBoothST.BallotSubmitted = ballotSubmittedEvents[ballotSubmittedEvents.length - 1] as! VoteBoothST.BallotSubmitted

    Test.assertEqual(ballotSubmittedEvent._ballotId, storedBallotId!)
    Test.assertEqual(ballotSubmittedEvent._voterAddress, storedBallotOwner!)
}

access(all) fun testBallotRevokeAccount01() {
    // In order to be able to revoke the ballot previously submitted by account01, I need to submit another one with the default option. But I still need a new ballot in account01 VoteBox
    // Get the initial number of minted and submitted ballots
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    let initialTotalBallotsSubmitted: UInt64 = scResult.returnValue as! UInt64

    // Capture the parameters for the Ballot in account02, which is still in account02's VoteBox, and the one already submitted for account01. This one is irrecoverable because it was submitted to the deployer's BallotBox, but I can revoke it by submitting another one with the default option, and validate its parameters from the event emitted. I can't get its parameters from its VoteBox at this point, but that's why I saved all the Ballot data into the ballots struts.
    let storedBallotId01: UInt64 = ballots[account01.address]!

    // The data for the Ballot in account01 should be out of the OwnerControl but the one for account02 should still be there. Check it
    scResult = executeScript(
        getOwnerControlBallotIdSc,
        [deployer.address, account01.address]
    )

    var ownerControlBallotId01: UInt64? = scResult.returnValue as! UInt64?

    // This one should be nil
    Test.assertEqual(ownerControlBallotId01, nil)

    scResult = executeScript(
        getOwnerControlOwnerSc,
        [deployer.address, storedBallotId01]
    )

    var ownerControlOwner01: Address? = scResult.returnValue as! Address?

    // No owner should be set in the OwnerControl struct for account01
    Test.assertEqual(ownerControlOwner01, nil)

    // All is consistent, it seems. Proceed with getting a new Ballot to account01
    var txResult: Test.TransactionResult = executeTransaction(
        mintBallotToAccountTx,
        [account01.address],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // Adjust the event counter for Ballots Minted
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1

    // And extract the new Ballot parameters
    let ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)

    let ballotMintedEvent: VoteBoothST.BallotMinted = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

    let newBallotId: UInt64 = ballotMintedEvent._ballotId
    let newBallotOwner: Address = ballotMintedEvent._voterAddress

    // Validate that these two parameters are in the OwnerControl resource
    scResult = executeScript(
        getOwnerControlBallotIdSc,
        [deployer.address, account01.address]
    )

    ownerControlBallotId01 = scResult.returnValue as! UInt64?

    Test.assertEqual(ownerControlBallotId01!, newBallotId)

    scResult = executeScript(
        getOwnerControlOwnerSc,
        [deployer.address, ownerControlBallotId01!]
    )

    ownerControlOwner01 = scResult.returnValue as! Address?

    Test.assertEqual(ownerControlOwner01!, newBallotOwner)

    // Submit both account01 and account02 Ballots with the default option to revoke them both
    txResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [0 as UInt8],
        account01
        )

    Test.expect(txResult, Test.beSucceeded())

    // The revoking from account01 should reduce the total ballots minted by 2: the old submitted ballot was burned, as well as the new one use to do the revoking. But no ballots should have been added to the submitted total
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalMintedBallots: UInt64 = scResult.returnValue as! UInt64

    // So, since the beginning of this test, I've minted one more Ballot (to account01) but burned 2 at this exact point (the new Ballot used to revoke the one from account01 and the old Ballot as well), so, I should have + 1 - 2 = -1 total minted Ballots from the initial value
    Test.assertEqual(initialTotalBallotsMinted - 1, finalTotalMintedBallots)

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    let finalTotalSubmittedBallots: UInt64 = scResult.returnValue as! UInt64

    Test.assertEqual(initialTotalBallotsSubmitted, finalTotalSubmittedBallots)

    // There should be one BallotRevoked event in storage
    // Also, increment the event counter for ballots minted to account with the new one minted to account01
    eventNumberCount[ballotRevokedEventType] = eventNumberCount[ballotRevokedEventType]! + 1
    // The previous revoking should have set 2 ballots to be burned as well
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 2
    // Same for the resourceDestroyed
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 2

    // Grab the event list
    var ballotRevokedEvents: [AnyStruct] = Test.eventsOfType(ballotRevokedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)

    Test.assertEqual(eventNumberCount[ballotRevokedEventType]!, ballotRevokedEvents.length)
    Test.assertEqual(eventNumberCount[contractDataInconsistentEventType]!, contractDataInconsistentEvents.length)
    Test.assertEqual(eventNumberCount[ballotBurnedEventType]!, ballotBurnedEvents.length)
    Test.assertEqual(eventNumberCount[resourceDestroyedEventType]!, resourceDestroyedEvents.length)
    
    // Capture the BallotRevoked event and check that the arguments match the expected ones
    var ballotRevokedEvent: VoteBoothST.BallotRevoked = ballotRevokedEvents[ballotRevokedEvents.length - 1] as! VoteBoothST.BallotRevoked

    Test.assertEqual(ballotRevokedEvent._ballotId!, ballots[account01.address]!)
    Test.assertEqual(ballotRevokedEvent._voterAddress, account01.address)

    // After revoking, make sure the OwnerControl has removed the entries related to the new Ballot issued to account01
    scResult = executeScript(
        getOwnerControlBallotIdSc,
        [deployer.address, newBallotOwner]
    )

    ownerControlBallotId01 = scResult.returnValue as! UInt64?

    Test.assertEqual(ownerControlBallotId01, nil)

    scResult = executeScript(
        getOwnerControlOwnerSc,
        [deployer.address, newBallotId]
    )

    ownerControlOwner01 = scResult.returnValue as! Address?

    Test.assertEqual(ownerControlOwner01, nil)
}

// Revoke the Ballot from account02, which hasn't been cast yet. This should yield
access(all) fun testBallotRevokeAccount02() {
    let storedBallotId02: UInt64 = ballots[account02.address]!

    var scResult: Test.ScriptResult = executeScript(
        getOwnerControlBallotIdSc,
        [deployer.address, account02.address]
    )

    var ownerControlBallotId02: UInt64? = scResult.returnValue as! UInt64?

    scResult = executeScript(
        getOwnerControlOwnerSc,
        [deployer.address, storedBallotId02]
    )

    var ownerControlOwner02: Address? = scResult.returnValue as! Address?

    // But the one for account02 should match this account address
    Test.assertEqual(ownerControlOwner02!, account02.address)
    Test.assertEqual(ownerControlBallotId02!, storedBallotId02)

    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    let initialTotalBallotsSubmitted: UInt64 = scResult.returnValue as! UInt64

    // Done with the Ballot in account01. Revoke the one in account02. This one has not been cast so far, but the behavior should resemble the one thus far
    var txResult: Test.TransactionResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [VoteBoothST.defaultBallotOption],
        account02
    )

    Test.expect(txResult, Test.beSucceeded())

    // It is expected that one BallotRevoked event has been emitted but nothing more
    eventNumberCount[ballotRevokedEventType] = eventNumberCount[ballotRevokedEventType]! + 1

    // And one more BallotBurned should have been added as well
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    var ballotRevokedEvents: [AnyStruct] = Test.eventsOfType(ballotRevokedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // Validate the event counter
    Test.assertEqual(eventNumberCount[ballotRevokedEventType]!, ballotRevokedEvents.length)
    Test.assertEqual(eventNumberCount[ballotBurnedEventType]!,
    ballotBurnedEvents.length)
    Test.assertEqual(eventNumberCount[resourceDestroyedEventType]!, resourceDestroyedEvents.length)
    Test.assertEqual(eventNumberCount[contractDataInconsistentEventType]!, contractDataInconsistentEvents.length)

    // Check that the data in the BallotRevoked event matches the one for the Ballot in account02
    let ballotRevokedEvent: VoteBoothST.BallotRevoked = ballotRevokedEvents[ballotRevokedEvents.length - 1] as! VoteBoothST.BallotRevoked

    Test.assertEqual(storedBallotId02, ballotRevokedEvent._ballotId!)
    Test.assertEqual(account02.address, ballotRevokedEvent._voterAddress)

    // Validate that both parameters were removed from the OwnerControl
    scResult = executeScript(
        getOwnerControlBallotIdSc,
        [deployer.address, account02.address]
    )

    ownerControlBallotId02 = scResult.returnValue as! UInt64?

    Test.assertEqual(ownerControlBallotId02, nil)

    scResult = executeScript(
        getOwnerControlOwnerSc,
        [deployer.address, storedBallotId02]
    )

    ownerControlOwner02 = scResult.returnValue as! Address?

    Test.assertEqual(ownerControlOwner02, nil)

    // Finally, the total minted ballots should have been decremented by one but the submitted ones should have remained the same. That's one less than the current minted Ballots value and minus 3 regarding the initial minted Ballots
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalMintedBallots: UInt64 = scResult.returnValue as! UInt64

    // I got one Ballot removed from the total minted (the Ballot revoked)
    Test.assertEqual(initialTotalBallotsMinted - 1, finalTotalMintedBallots)

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    let finalTotalSubmittedBallots: UInt64 = scResult.returnValue as! UInt64

    // But the total number of submitted ballots should have remained the same
    Test.assertEqual(initialTotalBallotsSubmitted, finalTotalSubmittedBallots)
}

/*
    This test destroys all VoteBoxes used so far, i.e., for account01, account02 and account03. The last one (account03) still has a valid Ballot in it (I left it there on purpose), so check that the relevant events are emitted as well
*/
access(all) fun testDestroyVoteBox() {
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

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

    // Only the VoteBoxDestroyed event should have been incremented in this case.
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
    scResult = executeScript(
        getBallotIdSc,
        [account03.address]
    )

    let ballotToBurnId03: UInt64? = scResult.returnValue as! UInt64?

    scResult = executeScript(
        getBallotOwnerSc,
        [account03.address]
    )

    let ballotToBurnOwner03: Address = (scResult.returnValue as! Address?)!

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
    Test.assertEqual(voteBoxDestroyedEvent._ballotId!, ballotToBurnId03!)

    Test.assertEqual(ballotSetToBurnEvent._ballotId, ballotToBurnId03!)
    Test.assertEqual(ballotSetToBurnEvent._voterAddress, ballotToBurnOwner03)

    // Check how many Ballots are set to burn in the BurnBox
    scResult = executeScript(
        getHowManyBallotsToBurnSc,
        [deployer.address]
    )

    let ballotsSetToBurn: Int = scResult.returnValue as! Int

    if (printLogs) {
        log(
            "BurnBox in account "
            .concat(deployer.address.toString())
            .concat(" has ")
            .concat(ballotsSetToBurn.toString())
            .concat(" Ballots set to be burn!")
        )
    }

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

    // Only the BallotBurned and ResourceDestroyed events should have been incremented by 2 (because, unlike the VoteBox, a Ballot IS a NonFungibleToken.NFT, therefore it automatically emits this event)
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + ballotsSetToBurn
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + ballotsSetToBurn

    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)

    // Validate the remaining parameters
    let ballotBurnedEvent: VoteBoothST.BallotBurned = ballotBurnedEvents[ballotBurnedEvents.length - 1] as! VoteBoothST.BallotBurned

    Test.assertEqual(ballotBurnedEvent._ballotId!, ballotToBurnId03!)
    Test.assertEqual(ballotBurnedEvent._voterAddress!, ballotToBurnOwner03)

    // No ballots were minted in this test but one got burned. The total number should have been decreased by one at the end
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    Test.assertEqual(initialTotalBallotsMinted - UInt64(ballotsSetToBurn), finalTotalBallotsMinted)
}



/*
    This function completes this cycle by destroying all the VoteBoxes, which implies that the Ballots in the remaining 2 accounts that were not burned in the previous function are going to set to the deployer's BurnBox, to be destroyed after the cycles are done
*/
access(all) fun _testDestroyVoteBoxes() {
    var txResult: Test.TransactionResult? = nil

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

    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let initialTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

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
            getBallotIdSc,
            [account.address]
        )

        ballotToBurnId = scResult.returnValue as! UInt64?
        ballotsToBurnIds.append(ballotToBurnId!)

        scResult = executeScript(
            getBallotOwnerSc,
            [account.address]
        )

        ballotToBurnOwner = (scResult.returnValue as! Address?)
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

    // At the end of this test, the remaining burnableVoteBoxAccount.length ballots were burned, so the total ballots minted should have been decremented by this amount. Check it

    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    Test.assertEqual(initialTotalBallotsMinted - UInt64(burnableVoteBoxesAccounts.length), finalTotalBallotsMinted)
}

// TODO: Fix this because I've changed the names in the OwnerControl resource
// TODO: Continue with the advanced tests
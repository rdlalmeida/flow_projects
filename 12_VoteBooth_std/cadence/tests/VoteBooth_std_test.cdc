import Test
import "VoteBooth_std"
import BlockchainHelpers
import "NonFungibleToken"


access(all) let electionName: String = "World's best dog ever!"
access(all) let electionSymbol: String = "WBDE"
access(all) let electionLocation: String = "Campinho"
access(all) let electionBallot: String = "Who was the best dog this summer? Options: \n1 - Eddie, \n2 - Argus, \n3 - Both, \n4 - None"
access(all) let electionOptions: String = "1;2;3;4"

access(all) let expectedBallotPrinterAdminStoragePath: StoragePath = /storage/BallotPrinterAdmin
access(all) let expectedBallotPrinterAdminPublicPath: PublicPath = /public/BallotPrinterAdmin
access(all) let expectedBallotCollectionStoragePath: StoragePath = /storage/BallotBox
access(all) let expectedBallotCollectionPublicPath: PublicPath = /public/BallotBox
access(all) let expectedVoteBoxStoragePath: StoragePath = /storage/VoteBox
access(all) let expectedVoteBoxPublicPath: PublicPath = /public/VoteBox

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000007)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let accounts: [Test.TestAccount] = [account01, account02, account03]
access(all) let ballots: {String: {String: String}} = {}

// TRANSACTIONS

access(all) let testBallotPrinterTx: String = "../transactions/01_test_ballot_printer_admin.cdc"
access(all) let testBallotPrinterReferenceTx: String = "../transactions/02_test_ballot_printer_admin_reference.cdc"
access(all) let voteBoxCreationTx: String = "../transactions/03_create_vote_box.cdc"
access(all) let mintBallotToAccountTx: String = "../transactions/04_mint_ballot_to_account.cdc"

// SCRIPTS
access(all) let testVoteBoxSc: String = "../scripts/01_testVoteBox.cdc"
access(all) let getVoteOptionSc: String = "../scripts/02_getVoteOption.cdc"

// EVENTS
// Define the exact type of each expected event to be emitted with this contract
// NonFungibleToken events
access(all) let updatedEventType: Type = Type<NonFungibleToken.Updated>()
access(all) let withdrawnEventType: Type = Type<NonFungibleToken.Withdrawn>()
access(all) let depositedEventType: Type = Type<NonFungibleToken.Deposited>()
access(all) let resourceDestroyedEventType: Type = Type<NonFungibleToken.NFT.ResourceDestroyed>()

// VoteBooth_std events
access(all) let nonNilTokenReturnedEventType: Type = Type<VoteBooth_std.NonNilTokenReturned>()
access(all) let ballotMintedEventType: Type = Type<VoteBooth_std.BallotMinted>()
access(all) let ballotSubmittedEventType: Type = Type<VoteBooth_std.BallotSubmitted>()
access(all) let ballotModifiedEventType: Type = Type<VoteBooth_std.BallotModified>()
access(all) let ballotBurnedEventType: Type = Type<VoteBooth_std.BallotBurned>()
access(all) let contractDataInconsistentEventType: Type = Type<VoteBooth_std.ContractDataInconsistent>()

// This one is the setup where all the contracts (mains and dependencies) before anything else
access(all) fun setup() {
    let err3: Test.Error? = Test.deployContract(
        name: "VoteBooth_std",
        path: "../contracts/VoteBooth_std.cdc",
        arguments: [electionName, electionSymbol, electionBallot, electionLocation, electionOptions]
    )

    Test.expect(err3, Test.beNil())
}

// Test the contract getters. These ones grab these properties directly from the contract so these should be OK since there are no resources being created and moved around... yet
// VoteBooth_std.getElectionName()
access(all) fun _testGetElectionName() {
    Test.assertEqual(electionName, VoteBooth_std.getElectionName())
}
// VoteBooth_std.getElectionSymbol()
access(all) fun _testGetElectionSymbol() {
    Test.assertEqual(electionSymbol, VoteBooth_std.getElectionSymbol())
}

// VoteBooth_std.getElectionLocation()
access(all) fun _testGetElectionLocation() {
    Test.assertEqual(electionLocation, VoteBooth_std.getElectionLocation())
}

// VoteBooth_std.getElectionBallot()
access(all) fun _testGetElectionBallot() {
    Test.assertEqual(electionBallot, VoteBooth_std.getElectionBallot())
}

// VoteBooth_std.getElectionOptions()
access(all) fun _testGetElectionOptions() {
    let options: [UInt64] = VoteBooth_std.getElectionOptions()

    log("Current options = ")
    log(options)

    // Convert the options parameter from a String to a [UInt64] to be able to compare the things
    var parsedElectionOptions: [UInt64] = []
    let optionElements: [String] = electionOptions.split(separator: ";")
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
    Test.assertEqual(VoteBooth_std.ballotPrinterAdminStoragePath, expectedBallotPrinterAdminStoragePath)

    Test.assertEqual(VoteBooth_std.ballotPrinterAdminPublicPath, expectedBallotPrinterAdminPublicPath)

    Test.assertEqual(VoteBooth_std.ballotCollectionStoragePath, expectedBallotCollectionStoragePath)

    Test.assertEqual(VoteBooth_std.ballotCollectionPublicPath, expectedBallotCollectionPublicPath)

    Test.assertEqual(VoteBooth_std.voteBoxPublicPath, expectedVoteBoxPublicPath)
    Test.assertEqual(VoteBooth_std.voteBoxStoragePath, expectedVoteBoxStoragePath)
}

access(all) fun _testDefaultParameters() {
    Test.assertEqual(VoteBooth_std.totalBallotsMinted, 0 as UInt64)
    Test.assertEqual(VoteBooth_std.totalBallotsSubmitted, 0 as UInt64)

    // ballotOwners: {UInt64: Address}
    Test.assert(VoteBooth_std.getBallotOwners() == {})

    // owners: {Address: UInt64}
    Test.assert(VoteBooth_std.getOwners() == {})
}

access(all) fun _testMinterLoading() {
    // Run the corresponding transaction
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotPrinterTx,
        [],
        deployer
    )

    // This transaction should emit a bunch of events and, if all, goes well, should NOT emit a warning event. Yep, I'm using those
    Test.expect(txResult01, Test.beSucceeded())

    var ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // If the transaction was OK, the first 3 events should have been emitted, but not the 4th one.
    Test.assertEqual(ballotMintedEvents.length, 1)
    Test.assertEqual(ballotBurnedEvents.length, 1)
    Test.assertEqual(resourceDestroyedEvents.length, 1)
    Test.assertEqual(contractDataInconsistentEvents.length, 0)

    // The expectation, also, is that this transaction should fail if a someone other than the contract deployer tries to run it. Test it
    let txResult02: Test.TransactionResult = executeTransaction(
        testBallotPrinterTx,
        [],
        account01
    )

    Test.expect(txResult02, Test.beFailed())

    // Also, none of the previous events should be emitted as well
    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // NOTE: This set of assertions tests for the same number of events as before, even after running the 'eventsOfType' function again.
    // If all went well, tx02 failed, therefore it reverted the state of the blockchain and didn't emitted any events, therefore the event array should remain unchanged.
    Test.assertEqual(ballotMintedEvents.length, 1)
    Test.assertEqual(ballotBurnedEvents.length, 1)
    Test.assertEqual(resourceDestroyedEvents.length, 1)
    Test.assertEqual(contractDataInconsistentEvents.length, 0)
}

access(all) fun _testMinterReference() {
    // This function runs a similar transaction but using references instead of loading the resource
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotPrinterReferenceTx,
        [],
        deployer
    )

    Test.expect(txResult01, Test.beSucceeded())

    var ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)
    var ballotBurnedEvents: [AnyStruct] = Test.eventsOfType(ballotBurnedEventType)
    var resourceDestroyedEvents: [AnyStruct] = Test.eventsOfType(resourceDestroyedEventType)
    var contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)

    // This ones should match the ones used in the previous test case. Since tests occur in a continuum, the previous transaction is going to emit new events which add to the previous ones already. I need to take this into account
    Test.assertEqual(ballotMintedEvents.length, 2)
    Test.assertEqual(ballotBurnedEvents.length, 2)
    Test.assertEqual(resourceDestroyedEvents.length, 2)
    Test.assertEqual(contractDataInconsistentEvents.length, 0)

    let txResult02: Test.TransactionResult = executeTransaction(
        testBallotPrinterReferenceTx,
        [],
        account01
    )
    
    Test.expect(txResult02, Test.beFailed())

    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)

    // Same as before, the event quantities should remain unchanged
    Test.assertEqual(ballotMintedEvents.length, 2)
    Test.assertEqual(ballotBurnedEvents.length, 2)
    Test.assertEqual(resourceDestroyedEvents.length, 2)
    Test.assertEqual(contractDataInconsistentEvents.length, 0)
}

// Mint and transfer a BallotNFT to each of the 3 accounts configured
access(all) fun testVoteBoxCreation() {
    // Test the existence of a VoteBox in each of the test accounts. It should not have none
    for account in accounts {
        let scriptResult: Test.ScriptResult = executeScript(
            testVoteBoxSc,
            [account.address]
        )

        Test.assertEqual(scriptResult.returnValue!, false)
    }

    // Try to mint a ballot to each of the three test accounts. It should fail because there are no VoteBoxes yet
    for account in accounts {
        let txResult: Test.TransactionResult = executeTransaction(
            mintBallotToAccountTx,
            [account.address],
            deployer
        )

        Test.expect(txResult, Test.beFailed())
    }

    // Create the voteBoxes for each account and run the test script again
    for account in accounts {
        let txResult: Test.TransactionResult = executeTransaction(
            voteBoxCreationTx,
            [],
            account
        )

        Test.expect(txResult, Test.beSucceeded())

        let scpResult: Test.ScriptResult = executeScript(
            testVoteBoxSc,
            [account.address]
        )

        Test.assertEqual(scpResult.returnValue!, true)
    }
}

access(all) fun testMintBallotToAccount() {
    for account in accounts {
        let txResult: Test.TransactionResult = executeTransaction(
            mintBallotToAccountTx,
            [account.address],
            deployer
        )

        Test.expect(txResult, Test.beSucceeded())

        // Just to be sure, capture data inconsistency events as well, the expectation is that none should be emitted
        let contractDataInconsistentEvents: [AnyStruct] = Test.eventsOfType(contractDataInconsistentEventType)
    }


    // Grab all ballot emitted events
    let ballotMintedEvents: [AnyStruct] = Test.eventsOfType(ballotMintedEventType)

    // A successful run contains, at least, 3 of the last events
    Test.assert(ballotMintedEvents.length >= 3)

    // Only the last 3 are relevant. Extract their data to populate the ballot dictionary with the characteristics

    log("Ballot Minted Events")
    log(ballotMintedEvents)

    for index, event in ballotMintedEvents {
        if (index > 2) {
            // For loops in Cadence are not very flexible. I want to process only the last 3 elements of this array. 
            // Since I cannot manipulate the index variable as in other languages, I need to be creative with this one. If more than 3 elements were processed, stop this
            break
        }

        let currentEvent: VoteBooth_std.BallotMinted = ballotMintedEvents[ballotMintedEvents.length - 1 - index] as! VoteBooth_std.BallotMinted

        let scResult: Test.ScriptResult = executeScript(
            getVoteOptionSc,
            [currentEvent._voterAddress, currentEvent._ballotId]
        )

        ballots[currentEvent._voterAddress.toString()] = {
            "owner_address": currentEvent._voterAddress.toString(),
            "id": currentEvent._ballotId.toString(),
            "metadata": scResult.returnValue as! String
        }
    }

    log("Current Ballots: ")
    log(ballots)
}
import Test
import BlockchainHelpers
import "VoteBoothST"
import "NonFungibleToken"

access(all) let electionName: String = "World's best dog ever!"
access(all) let electionSymbol: String = "WBDE"
access(all) let electionLocation: String = "Campinho"
access(all) let electionBallot: String = "Who was the best dog this Summer? Options: \n1 - Eddie, \n2 - Argus, \n3 - Both, \n4 - None"
access(all) let electionOptions: [UInt8] = [1, 2, 3, 4]

access(all) let printLogs: Bool = false

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000008)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let account04: Test.TestAccount = Test.createAccount()
access(all) let account05: Test.TestAccount = Test.createAccount()

access(all) let accounts: [Test.TestAccount] = [account01, account02, account03, account04, account05]

access(all) var ballots: {Address: UInt64} = {}

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
access(all) let burnBallotsFromBurnBoxTx: String = "../transactions/10_burn_ballots_from_burn_box.cdc"
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

access(all) var updatedEvents: [AnyStruct] = []
access(all) var withdrawnEvents: [AnyStruct] = []
access(all) var depositedEvents: [AnyStruct] = []
access(all) var resourceDestroyedEvents: [AnyStruct] = []
access(all) var nonNilTokenReturnedEvents: [AnyStruct] = []
access(all) var ballotMintedEvents: [AnyStruct] = []
access(all) var ballotSubmittedEvents: [AnyStruct] = []
access(all) var ballotModifiedEvents: [AnyStruct] = []
access(all) var ballotBurnedEvents: [AnyStruct] = []
access(all) var ballotRevokedEvents: [AnyStruct] = []
access(all) var contractDataInconsistentEvents: [AnyStruct] = []
access(all) var voteBoxCreatedEvents: [AnyStruct] = []
access(all) var voteBoxDestroyedEvents: [AnyStruct] = []
access(all) var ballotBoxCreatedEvents: [AnyStruct] = []
access(all) var ballotSetToBurnEvents: [AnyStruct] = []

// This function updates the quantity of Events for each event considered and validates them against the eventNumberCount values
access(all) fun validateEvents() {
    // Refresh every event structure
    updatedEvents = Test.eventsOfType(updatedEventType)
    withdrawnEvents = Test.eventsOfType(withdrawnEventType)
    depositedEvents = Test.eventsOfType(depositedEventType)
    resourceDestroyedEvents = Test.eventsOfType(resourceDestroyedEventType)
    nonNilTokenReturnedEvents = Test.eventsOfType(nonNilTokenReturnedEventType)
    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotSubmittedEvents = Test.eventsOfType(ballotSubmittedEventType)
    ballotModifiedEvents = Test.eventsOfType(ballotModifiedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    ballotRevokedEvents = Test.eventsOfType(ballotRevokedEventType)
    contractDataInconsistentEvents = Test.eventsOfType(contractDataInconsistentEventType)
    voteBoxCreatedEvents = Test.eventsOfType(voteBoxCreatedEventType)
    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    ballotBoxCreatedEvents = Test.eventsOfType(ballotBoxCreatedEventType)
    ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)

    // Test if the counters match the length of the event arrays
    Test.assertEqual(updatedEvents.length, eventNumberCount[updatedEventType]!)
    Test.assertEqual(withdrawnEvents.length, eventNumberCount[withdrawnEventType]!)
    Test.assertEqual(depositedEvents.length, eventNumberCount[depositedEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(nonNilTokenReturnedEvents.length, eventNumberCount[nonNilTokenReturnedEventType]!)
    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotSubmittedEvents.length, eventNumberCount[ballotSubmittedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(ballotRevokedEvents.length, eventNumberCount[ballotRevokedEventType]!)
    Test.assertEqual(contractDataInconsistentEvents.length, eventNumberCount[contractDataInconsistentEventType]!)
    Test.assertEqual(voteBoxCreatedEvents.length, eventNumberCount[voteBoxCreatedEventType]!)
    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ballotBoxCreatedEvents.length, eventNumberCount[ballotBoxCreatedEventType]!)
    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)
}

access(all) struct ownerControlEntry {
    access(all) let ballotId: UInt64?
    access(all) let owner: Address?

    init(_ballotId: UInt64?, _owner: Address?) {
        self.ballotId = _ballotId
        self.owner = _owner
    }
}

// Simple function to help with getting the totalMintedBallots and totalSubmittedBallots in a single function
access(all) fun getBallotTotals(): {String: UInt64} {
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    var ballotTotals: {String: UInt64} = {}

    ballotTotals["minted"] = scResult.returnValue as! UInt64

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    ballotTotals["submitted"] = scResult.returnValue as! UInt64

    return ballotTotals
}

// Another function to simplify the retrieval of information, in this case, the stuff in the OwnerControl resource
access(all) fun getOwnerControlEntry(ballotId: UInt64, owner: Address): ownerControlEntry {
    var scResult: Test.ScriptResult = executeScript(
        getOwnerControlBallotIdSc,
        [deployer.address, owner]
    )

    let ownerControlBallotId: UInt64? = scResult.returnValue as! UInt64?

    scResult = executeScript(
        getOwnerControlOwnerSc,
        [deployer.address, ballotId]
    )

    let ownerControlOwner: Address? = scResult.returnValue as! Address?

    return ownerControlEntry(_ballotId: ownerControlBallotId, _owner: ownerControlOwner)
}

access(all) fun setup() {
    let err: Test.Error? = Test.deployContract(
        name: "VoteBoothST",
        path: "../contracts/VoteBoothST.cdc",
        arguments: [electionName, electionSymbol, electionBallot, electionLocation, electionOptions, printLogs]
    )

    Test.expect(err, Test.beNil())

    // Increment the counter for the events expected to be emitted in this setup phase
    eventNumberCount[ballotBoxCreatedEventType] = eventNumberCount[ballotBoxCreatedEventType]! + 1
    
    log(
        "Deployer account address = "
        .concat(deployer.address.toString())
    )

    for index, account in accounts {
        log(
            "Account 0"
            .concat((index + 1).toString())
            .concat(" address = ")
            .concat(account.address.toString())
        )
    }
}

access(all) fun testCreateVoteBoxes() {
    var txResult: Test.TransactionResult? = nil
    var voteBoxCreatedEvent: VoteBoothST.VoteBoxCreated? = nil
    var voteBoxAddress: Address? = nil
    
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
        validateEvents()

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

    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    // No ballots minted with this one as well. Test it
    Test.assertEqual(initialTotalBallotsMinted, finalTotalBallotsMinted)

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    let finalTotalBallotsSubmitted: UInt64 = scResult.returnValue as! UInt64

    Test.assertEqual(initialTotalBallotsSubmitted, finalTotalBallotsSubmitted)
}

/*
    This function, unlike the preceding one, serves mainly to test the transaction that mints and transfers NFTs in bulk
*/
access(all) fun testBallotMintingToVoteBoxes() {
    var txResult: Test.TransactionResult? = nil
    var storedBallotId: UInt64? = nil

    var ballotMintedEvent: VoteBoothST.BallotMinted? = nil

    let addresses: [Address] = [account01.address, account02.address, account03.address, account04.address, account05.address]

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

    for account in accounts {
        txResult = executeTransaction(
            mintBallotToAccountTx,
            [account.address],
            deployer
        )

        Test.expect(txResult, Test.beSucceeded())
        
        if (VoteBoothST.printLogs) {
            log(
                "Successfully minted a Ballot for account "
                .concat(account.address.toString())
            )
        }

        // Refresh the BallotMinted event list
        ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)

        ballotMintedEvent = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted?

        // Populate the ballots struct accordingly
        ballots[ballotMintedEvent!._voterAddress] = ballotMintedEvent!._ballotId
    }



    // Populate the event structures

    // Increment the minted events counter by the number of addresses in the input array
    // All the remaining structures should have not been changed
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + accounts.length

    // Validate the event count
    validateEvents()

    // This test should have increase the total of ballots minted by the size of the addresses array
    scResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    let finalTotalBallotsMinted: UInt64 = scResult.returnValue as! UInt64

    // The total number of ballots minted should have been incremented by the number of accounts in the main array
    Test.assertEqual(initialTotalBallotsMinted + UInt64(accounts.length), finalTotalBallotsMinted)

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    // But the number of total ballots submitted should have remained the same
    let finalTotalBallotsSubmitted: UInt64 = scResult.returnValue as! UInt64

    Test.assertEqual(initialTotalBallotsSubmitted, finalTotalBallotsSubmitted)


}

/* 
    This function follows on the previous ones, i.e., it expects a valid VoteBox in each account in the accounts array with one and only one Ballot in it.
    This test tries to cast an invalid Ballot in some capacity for each of the accounts considered
*/
access(all) fun testSubmitInvalidBallots() {
    let initialBallotTotals: {String: UInt64} = getBallotTotals()

    // Try to submit a ballot with a valid option but signed by the one account that is unable to do so (deployer)
    var txResult: Test.TransactionResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [1 as UInt8],
        deployer
    )

    Test.expect(txResult, Test.beFailed())

    // Next, try to submit a Ballot with an invalid option
    txResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [100 as UInt8],
        account03
    )

    // This one should fail as well
    Test.expect(txResult, Test.beFailed())

    var ownerControlEntry05: ownerControlEntry = getOwnerControlEntry(ballotId: ballots[account05.address]!, owner: account05.address)


    Test.assertEqual(ownerControlEntry05.ballotId!, ballots[account05.address]!)

    Test.assertEqual(ownerControlEntry05.owner!, account05.address)

    // Next, submit a ballot to be Revoked, adjust the counters, validate events and try to submit another ballot afterwards
    txResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [VoteBoothST.defaultBallotOption],
        account05
    )

    // This one should have been successful
    Test.expect(txResult, Test.beSucceeded())

    // The Ballot from account05 should have been revoked, therefore burned at some point. Adjust the event counters
    eventNumberCount[ballotRevokedEventType] = eventNumberCount[ballotRevokedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    validateEvents()

    // After revoking, the OwnerControl entries for account05 Ballot should be nil
    ownerControlEntry05 = getOwnerControlEntry(ballotId: ballots[account05.address]!, owner: account05.address)
    
    Test.assertEqual(ownerControlEntry05.ballotId, nil)
    Test.assertEqual(ownerControlEntry05.owner, nil)

    // Try to submit a valid ballot for the same account after revoking the old one in storage. This should fail because account05 VoteBox is empty
    txResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [1 as UInt8],
        account05
    )

    Test.expect(txResult, Test.beFailed())

    let finalBallotTotals: {String:UInt64} = getBallotTotals()

    // No Ballots were submitted but one was burned. Test that the totals are consistent
    Test.assertEqual(initialBallotTotals["minted"]! - 1, finalBallotTotals["minted"]!)
    Test.assertEqual(initialBallotTotals["submitted"]!, finalBallotTotals["submitted"]!)
}

/*
    This test submits a couple of valid Ballots.
*/
access(all) fun testSubmitValidBallots() {
    // Start by getting the initial Ballot totals
    let initialBallotTotals: {String: UInt64} = getBallotTotals()

    // Begin by minting a new Ballot to account05 to compensate for the one that was revoked in the last test
    var txResult: Test.TransactionResult = executeTransaction(
        mintBallotToAccountTx,
        [account05.address],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // Adjust the event counters and capture the BallotMinted event to adjust the new ballotId for the ballots dictionary for account05
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1

    // Refresh the BallotMinted event array
    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)

    var ballotMintedEvent: VoteBoothST.BallotMinted = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

    var ballotSubmittedEvent: VoteBoothST.BallotSubmitted? = nil

    ballots[account05.address] = ballotMintedEvent._ballotId

    // Create a simple array with a bunch of valid options to use in the vote casting
    let votesToCast: [UInt8] = [2, 1, 3, 2, 1]

    var tempOwnerControlEntry: ownerControlEntry? = nil

    // Submit each Ballot in the corresponding account VoteBox according to one of the options above
    for index, account in accounts {
        // Cast ballots only to 4 accounts. Account04 is going to have its Ballot revoked
        if (account.address != account04.address) {
            // Begin by checking that the Ballot parameters in the ballots dictionary matches the data retrieved from the OwnerControl resource
            tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballots[account.address]!, owner: account.address)

            Test.assertEqual(tempOwnerControlEntry!.ballotId!, ballots[account.address]!)
            Test.assertEqual(tempOwnerControlEntry!.owner!, account.address)

            // Submit the Ballot for this account
            txResult = executeTransaction(
                submitBallotToBallotBoxTx,
                [votesToCast[index]],
                account
            )

            Test.expect(txResult, Test.beSucceeded())

            // This submission means a BallotSubmitted event emitted
            eventNumberCount[ballotSubmittedEventType] = eventNumberCount[ballotSubmittedEventType]! + 1

            validateEvents()


            ballotSubmittedEvent = ballotSubmittedEvents[ballotSubmittedEvents.length - 1] as! VoteBoothST.BallotSubmitted

            // Check that the parameters in the BallotSubmitted event match the ones in the ballots dictionary
            Test.assertEqual(ballotSubmittedEvent!._ballotId, ballots[account.address]!)
            Test.assertEqual(ballotSubmittedEvent!._voterAddress, account.address)

            // After submission, the OwnerControl resource should have the entries associated to this account cleaned (nil). Validate this
            tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballots[account.address]!, owner: account.address)

            Test.assertEqual(tempOwnerControlEntry!.ballotId, nil)
            Test.assertEqual(tempOwnerControlEntry!.owner, nil)

            // All good. Done with this one. Move to the next account
        }
    }

    // Get the final Ballot totals. I should have one more above the initial minted totals (because of the new one for account05) and as many more in the submitted totals as the number of accounts, minus the one skipped for account05 as well
    let finalBallotTotals: {String: UInt64} = getBallotTotals()

    Test.assertEqual(initialBallotTotals["minted"]! + 1, finalBallotTotals["minted"]!)
    Test.assertEqual(initialBallotTotals["submitted"]! + UInt64(accounts.length) - 1, finalBallotTotals["submitted"]!)
}

/*
    This test revokes some of the Ballots in the account's VoteBoxes, namely the one from account03 and account04 that wasn't cast yet
*/
access(all) fun testRevokeBallots() {
    // Grab the initial ballot totals
    let initialBallotTotals: {String: UInt64} = getBallotTotals()

    // Validate that there are 4 submitted Ballots thus far
    Test.assertEqual(initialBallotTotals["submitted"]!, 4 as UInt64)

    // I'm going to revoke the Ballot previously submitted from account03 by getting a new, empty Ballot into this account VoteBox and then submit this new one with the default option
    // Save the parameters of the Ballot submitted from account03, which currently exist only in the ballots resource
    let oldBallotId03: UInt64 = ballots[account03.address]!
    let oldOwner03: Address = account03.address

    // Get the same parameters for the Ballot that wasn't cast and it is still in account04 VoteBox
    let oldBallotId04: UInt64 = ballots[account04.address]!
    let oldOwner04: Address = account04.address

    // Mint a new Ballot onto account03 and get the new parameters of it as well
    var txResult :Test.TransactionResult = executeTransaction(
        mintBallotToAccountTx,
        [account03.address],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // Account for the new Ballot minted and verify
    eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1

    validateEvents()

    var ballotMintedEvent: VoteBoothST.BallotMinted = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

    let newBallotId03: UInt64 = ballotMintedEvent._ballotId
    let newOwner03: Address = ballotMintedEvent._voterAddress

    // I've validated that the OwnerControl resource got all entries related to the old Ballot in account03 were set to nil in the previous test
    // Now I'm just validating that minting a new Ballot for account03 did filled the proper entries in the OwnerControl resource
    var tempOwnerControlEntry: ownerControlEntry = getOwnerControlEntry(ballotId: newBallotId03, owner: account03.address)

    Test.assertEqual(newBallotId03, tempOwnerControlEntry.ballotId!)
    Test.assertEqual(newOwner03, tempOwnerControlEntry.owner!)

    // Validate that no unexpected events were emitted thus far
    validateEvents()

    // Try to cast a Ballot with the default option from account02. It should fail because account02 has no Ballots in its VoteBox at this point
    txResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [VoteBoothST.defaultBallotOption],
        account02
    )

    Test.expect(txResult, Test.beFailed())

    // All good. Revoke both Ballots from account03 (already submitted) and for account04
    txResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [VoteBoothST.defaultBallotOption],
        account03
    )

    Test.expect(txResult, Test.beSucceeded())

    // Process all events
    eventNumberCount[ballotRevokedEventType] = eventNumberCount[ballotRevokedEventType]! + 1
    // The revoking of the Ballot in account03 should have trigger 2 ballots to be burned: the one submitted with the default option and the one already submitted
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 2
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 2

    // Refresh the BallotRevoked event array before grabbing the last one
    ballotRevokedEvents = Test.eventsOfType(ballotRevokedEventType)

    var ballotRevokedEvent: VoteBoothST.BallotRevoked = ballotRevokedEvents[ballotRevokedEvents.length - 1] as! VoteBoothST.BallotRevoked

    Test.assertEqual(oldBallotId03, ballotRevokedEvent._ballotId!)
    Test.assertEqual(oldOwner03, ballotRevokedEvent._voterAddress)

    // Validate that the parameters of the new Ballot for account03 were removed from the OwnerControl
    tempOwnerControlEntry = getOwnerControlEntry(ballotId: newBallotId03, owner: newOwner03)

    Test.assertEqual(tempOwnerControlEntry.ballotId, nil)
    Test.assertEqual(tempOwnerControlEntry.owner, nil)
    
    validateEvents()

    // Check that the parameters for the Ballot in account04 are still in the Owner control
    tempOwnerControlEntry = getOwnerControlEntry(ballotId: oldBallotId04, owner: oldOwner04)

    Test.assertEqual(tempOwnerControlEntry.ballotId!, oldBallotId04)
    Test.assertEqual(tempOwnerControlEntry.owner!, oldOwner04)

    // And now for the one in account04
    txResult = executeTransaction(
        submitBallotToBallotBoxTx,
        [VoteBoothST.defaultBallotOption],
        account04
    )

    // This should have triggered 1 BallotRevoked, 1 BallotBurned, and 1 ResourceDestroyed and nothing else more
    eventNumberCount[ballotRevokedEventType] = eventNumberCount[ballotRevokedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    validateEvents()

    ballotRevokedEvent = ballotRevokedEvents[ballotRevokedEvents.length -1] as! VoteBoothST.BallotRevoked

    Test.assertEqual(ballotRevokedEvent._ballotId!, oldBallotId04)
    Test.assertEqual(ballotRevokedEvent._voterAddress, oldOwner04)

    // Check the parameters from the revoked Ballot from account03 were removed from the OwnerControl
    tempOwnerControlEntry = getOwnerControlEntry(ballotId: oldBallotId03, owner: oldOwner03)

    Test.assertEqual(tempOwnerControlEntry.ballotId, nil)
    Test.assertEqual(tempOwnerControlEntry.owner, nil)

    // Validate the Ballot totals
    let finalBallotTotals: {String: UInt64} = getBallotTotals()

    // I should have 1 more for the total minted (account03) but minus 3 because of the revoked ones(2 x account03 + account04), so minus 2 over the total minted
    Test.assertEqual(initialBallotTotals["minted"]! - 2, finalBallotTotals["minted"]!)

    // As for the submitted ones, I shall have one less from the initial ones from the one in account03 that was revoked
    Test.assertEqual(initialBallotTotals["submitted"]! - 1, finalBallotTotals["submitted"]!)
}

/*
    And this one destroys all the VoteBoxes for all accounts and makes sure the relevant counters make sense and the right Events are emitted. All Ballots in the test accounts are either submitted or revoked, therefore I need to mint new ones to trigger the BallotSetTuBurn event logic.
*/
access(all) fun _destroyVoteBoxes() {
    // Lets start by getting the total ballots, as usual
    let initialBallotTotals: {String: UInt64} = getBallotTotals()

    // There are no Ballots in any of the VoteBoxes. To trigger the Ballot burning process for non-submitted Ballots, I need to put some more in the VoteBoxes.
    // Let's do so for a smaller subset of the test accounts
    let smallAccounts: [Test.TestAccount] = [account02, account03, account04]

    var txResult: Test.TransactionResult? = nil
    var ballotMintedEvent: VoteBoothST.BallotMinted? = nil
    var tempOwnerControlEntry: ownerControlEntry? = nil

    for account in smallAccounts {
        txResult = executeTransaction(
            mintBallotToAccountTx,
            [account.address],
            deployer
        )

        Test.expect(txResult!, Test.beSucceeded())

        // Refresh the array of BallotMinted events
        ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)

        ballotMintedEvent = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

        // Update the ballots struct with the data from the event
        ballots[account.address] = ballotMintedEvent!._ballotId

        // Validate that the new Ballots were set in the OwnerControl structure
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballotMintedEvent!._ballotId, owner: ballotMintedEvent!._voterAddress)

        Test.assertEqual(ballots[account.address]!, tempOwnerControlEntry!.ballotId!)
        Test.assertEqual(account.address, tempOwnerControlEntry!.owner!)
    }

    // I've added 3 ballots to the 3 middle accounts of the accounts array. None of these Ballots is to be submitted. Proceed in destroying their VoteBoxes
    // Begin by destroying the VoteBoxes for account01 and account05. These are empty and therefore should not emit any BallotSetToBurn events
    txResult = executeTransaction(
        destroyVoteBoxTx,
        [],
        account01
    )

    Test.expect(txResult, Test.beSucceeded())

    // Make sure the OwnerControl has no entries related to the account01
    tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballots[account01.address]!, owner: account01.address)

    Test.assertEqual(tempOwnerControlEntry!.ballotId, nil)
    Test.assertEqual(tempOwnerControlEntry!.owner, nil)

    // Refresh the event array for the VoteBoxDestroyed ones
    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)

    // Grab the last one of these
    var voteBoxDestroyedEvent: VoteBoothST.VoteBoxDestroyed = voteBoxDestroyedEvents[voteBoxDestroyedEvents.length - 1] as! VoteBoothST.VoteBoxDestroyed

    // Increment the vent counter for this case
    eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1

    Test.assertEqual(voteBoxDestroyedEvent._ballotId, nil)
    Test.assertEqual(voteBoxDestroyedEvent._ballotsInBox, 0)

    // Repeat the process for account05
    txResult = executeTransaction(
        destroyVoteBoxTx,
        [],
        account05
    )

    Test.expect(txResult, Test.beSucceeded())

    tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballots[account05.address]!, owner: account05.address)

    Test.assertEqual(tempOwnerControlEntry!.ballotId, nil)
    Test.assertEqual(tempOwnerControlEntry!.owner, nil)

    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    voteBoxDestroyedEvent = voteBoxDestroyedEvents[voteBoxDestroyedEvents.length - 1] as! VoteBoothST.VoteBoxDestroyed

    eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1

    Test.assertEqual(voteBoxDestroyedEvent._ballotId, nil)
    Test.assertEqual(voteBoxDestroyedEvent._ballotsInBox, 0)

    var ballotSetToBurnEvent: VoteBoothST.BallotSetToBurn? = nil

    var ballotIdToBurn: [UInt64] = []
    var ownerToBurn: [Address] = []

    // Now for the accounts with a Ballot still in their VoteBoxes
    for account in smallAccounts {
        txResult = executeTransaction(
            destroyVoteBoxTx,
            [],
            account
        )

        Test.expect(txResult, Test.beSucceeded())

        // In this case, the Ballots were set to be burned, but are not yet burned, therefore there should be a valid entry to each in the OwnerControl resource, for now
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballots[account.address]!, owner: account.address)

        Test.assertEqual(tempOwnerControlEntry!.ballotId!, ballots[account.address]!)
        Test.assertEqual(tempOwnerControlEntry!.owner!, account.address)

        // Refresh the voteBoxDestroyed event count and event array
        voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)

        eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1

        voteBoxDestroyedEvent = voteBoxDestroyedEvents[voteBoxDestroyedEvents.length - 1] as! VoteBoothST.VoteBoxDestroyed

        Test.assertEqual(voteBoxDestroyedEvent._ballotId!, ballots[account.address]!)
        Test.assertEqual(voteBoxDestroyedEvent._ballotsInBox, 1)

        // Repeat the process for the BallotSetToBurn events that should have been emitted as well

        ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)
        
        eventNumberCount[ballotSetToBurnEventType] = eventNumberCount[ballotSetToBurnEventType]! + 1

        ballotSetToBurnEvent = ballotSetToBurnEvents[ballotSetToBurnEvents.length - 1] as! VoteBoothST.BallotSetToBurn

        // The BallotSetToBurn event should match the Ballot parameters in the ballots struct
        Test.assertEqual(ballotSetToBurnEvent!._ballotId, ballots[account.address]!)
        Test.assertEqual(ballotSetToBurnEvent!._voterAddress, account.address)

        // Save the id of the Ballot set to burn for future comparison
        ballotIdToBurn.append(ballotSetToBurnEvent!._ballotId)
        ownerToBurn.append(ballotSetToBurnEvent!._voterAddress)
    }

    validateEvents()

    // Burn the Ballots in the BurnBox and validate events
    txResult = executeTransaction(
        burnBallotsFromBurnBoxTx,
        [],
        deployer
    )

    // 3 Ballots should have been set to Burn. Check it
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + smallAccounts.length

    validateEvents()

    var ballotBurnedEvent: VoteBoothST.BallotBurned? = nil

    for index, account in smallAccounts {
        ballotBurnedEvent = ballotBurnedEvents[ballotBurnedEvents.length - 1 - index] as! VoteBoothST.BallotBurned

        // Test that the parameters of the Ballots burned are in the set that was set to Burn
        Test.assert(ballotIdToBurn.contains(ballotBurnedEvent!._ballotId!))
        Test.assert(ownerToBurn.contains(ballotBurnedEvent!._voterAddress!))

        // And test that the same parameters are off from the OwnerControl resource
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballotBurnedEvent!._ballotId!, owner: ballotBurnedEvent!._voterAddress!)

        Test.assertEqual(tempOwnerControlEntry!.ballotId, nil)
        Test.assertEqual(tempOwnerControlEntry!.owner, nil)
    }

    // Get the Ballot totals
    let finalBallotTotals: {String: UInt64} = getBallotTotals()

    // From the beginning of this test, I should have 3 more ballots minted but 3 burned as well, so no changes in the total minted, as well as in the totals submitted
    Test.assertEqual(initialBallotTotals["minted"]!, finalBallotTotals["minted"]!)
    Test.assertEqual(initialBallotTotals["submitted"]!, finalBallotTotals["submitted"]!)
}
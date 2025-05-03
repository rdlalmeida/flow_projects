import Test
import BlockchainHelpers
import "VoteBoothST"
import "NonFungibleToken"

access(all) let electionName: String = "World's best dog ever!"
access(all) let electionSymbol: String = "WBDE"
access(all) let electionLocation: String = "Campinho"
access(all) let electionBallot: String = "Who was the best dog this summer? Options: \n1 - Eddie, \n2 - Argus, \n3 - Both, \n4 - None"
// access(all) let electionOptions: String = "1;2;3;4"
access(all) let electionOptions: [UInt8] = [1, 2, 3, 4]

access(all) let printLogs: Bool = false

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000008)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let account04: Test.TestAccount = Test.createAccount()
access(all) let account05: Test.TestAccount = Test.createAccount()

access(all) let accounts: [Test.TestAccount] = [account01, account02, account03, account04, account05]
access(all) let addresses: [Address] = [account01.address, account02.address, account03.address, account04.address, account05.address]

/*
    This dictionary should be populated as
    "account name": {
            "address": <ADDRESS>,
            "ballotID": <BALLOT_ID>
            }
*/
access(all) let ballots: {Address: UInt64} = {}

// I'm going to use this one to keep track of Ballots that I want to revoke after submitting them (because after submitting a Ballot, it becomes irrecoverable and inaccessible)
access(all) let ballotsToRevoke: {Address: UInt64} = {}

// TRANSACTIONS
access(all) let createVoteBoxTx: String = "../transactions/05_create_vote_box.cdc"
access(all) let mintBallotToAccountTx: String = "../transactions/07_mint_ballot_to_account.cdc"
access(all) let submitBallotToBallotBoxTx: String = "../transactions/09_submit_ballot_to_ballot_box.cdc"
access(all) let burnBallotFromBurnBoxTx: String = "../transactions/10_burn_ballots_from_burn_box.cdc"
access(all) let destroyVoteBoxTx: String = "../transactions/11_destroy_vote_box.cdc"
access(all) let castVoteTx: String = "../transactions/12_cast_vote.cdc"
access(all) let submitBallotTx: String = "../transactions/13_submit_ballot.cdc"

// SCRIPTS
access(all) let getVoteOptionsSc: String = "../scripts/02_get_vote_option.cdc"
access(all) let getIDsSc: String = "../scripts/03_get_IDs.cdc"
access(all) let getBallotOwnersSc: String = "../scripts/04_get_ballot_owner.cdc"
access(all) let getTotalBallotsMintedSc: String = "../scripts/05_get_total_ballots_minted.cdc"
access(all) let getTotalBallotsSubmittedSc: String = "../scripts/06_get_total_ballots_submitted.cdc"
access(all) let getCurrentVoteOptionSc: String = "../scripts/07_get_current_vote_option.cdc"
access(all) let getHowManyBallotsToBurnSc: String = "../scripts/08_get_how_many_ballots_to_burn.cdc"
access(all) let getOwnerControlBallotIdSc: String = "../scripts/09_get_owner_control_ballot_id.cdc"
access(all) let getOwnerControlOwnerSc: String = "../scripts/10_get_owner_control_owner.cdc"

// EVENTS
// NonFungibleToken events
access(all) let updatedEventType: Type = Type<NonFungibleToken.Updated>()
access(all) let withdrawnEventType: Type = Type<NonFungibleToken.Withdrawn>()
access(all) let depositedEventType: Type = Type<NonFungibleToken.Deposited>()
access(all) let resourceDestroyedEventType: Type = Type<NonFungibleToken.NFT.ResourceDestroyed>()

// VoteBoothST events
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

access(all) fun validateEvents() {
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

    Test.assertEqual(updatedEvents.length, eventNumberCount[updatedEventType]!)
    Test.assertEqual(withdrawnEvents.length, eventNumberCount[withdrawnEventType]!)
    Test.assertEqual(resourceDestroyedEvents.length, eventNumberCount[resourceDestroyedEventType]!)
    Test.assertEqual(nonNilTokenReturnedEvents.length, eventNumberCount[nonNilTokenReturnedEventType]!)
    Test.assertEqual(ballotSubmittedEvents.length, eventNumberCount[ballotSubmittedEventType]!)
    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotModifiedEvents.length, eventNumberCount[ballotModifiedEventType]!)
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

access(all) fun getBallotTotals(): {String: UInt64} {
    var scResult: Test.ScriptResult = executeScript(
        getTotalBallotsMintedSc,
        []
    )

    var ballotsTotal: {String: UInt64} = {}

    ballotsTotal["minted"] = scResult.returnValue as! UInt64

    scResult = executeScript(
        getTotalBallotsSubmittedSc,
        []
    )

    ballotsTotal["submitted"] = scResult.returnValue as! UInt64

    return ballotsTotal
}

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
/* 
    IMPORTANT: This whole test suit is very, very based one VoteBox.getCurrentVote() and Ballot.getVote() functions, which should only be available for TEST and DEBUG purposed. At some point these functions should be deleted, or protected with an access(self) control access to maintain voter privacy. This means that, if this test is tried in a PROD version of the contract, most of these tests should FAIL because of that. Either take this into consideration, or revert these functions to access(all) to carry out the tests.
*/
access(all) fun setup() {
    let err: Test.Error? = Test.deployContract(
        name: "VoteBoothST",
        path: "../contracts/VoteBoothST.cdc",
        arguments: [electionName, electionSymbol, electionBallot, electionLocation, electionOptions, printLogs]
    )

    Test.expect(err, Test.beNil())

    var ballotBoxCreatedEvents: [AnyStruct] = Test.eventsOfType(ballotBoxCreatedEventType)

    eventNumberCount[ballotBoxCreatedEventType] = eventNumberCount[ballotBoxCreatedEventType]! + 1
    Test.assertEqual(ballotBoxCreatedEvents.length, eventNumberCount[ballotBoxCreatedEventType]!)

    let ballotBoxCreatedEvent: VoteBoothST.BallotBoxCreated = ballotBoxCreatedEvents[0] as! VoteBoothST.BallotBoxCreated

    Test.assertEqual(deployer.address, ballotBoxCreatedEvent._accountAddress)

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

    // The functions in this test module are advanced ones, so I need to prepare the test accounts accordingly, namely, I should put a VoteBox in each as part of the setup bit
    var txResult: Test.TransactionResult? = nil

    for index, account in accounts {
        txResult = executeTransaction(
            createVoteBoxTx,
            [],
            account
        )

        Test.expect(txResult, Test.beSucceeded())

        // Increment the event counter to keep things consistent
        eventNumberCount[voteBoxCreatedEventType] = eventNumberCount[voteBoxCreatedEventType]! + 1
    }
}

// Try to get the vote for each account at this stage. I should receive a nil in each case because there aren't any Ballots in these yet.
access(all) fun testGetEmptyVote() {
    var scResult: Test.ScriptResult? = nil

    for account in accounts {
        scResult = executeScript(
            getCurrentVoteOptionSc,
            [account.address]
        )

        let currentOption: Int? = scResult!.returnValue as! Int?

        Test.assertEqual(currentOption, nil)
    }
}

/*
    This test mints an empty Ballot to the first three test accounts: account01, account02, and account03. I'm leaving the remaining accounts empty for now
*/
access(all) fun testMintEmptyBallotsToAccounts() {
    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil
    var ballotMintedEvent: VoteBoothST.BallotMinted? = nil

    // Take note of the initial amount of ballots minted and submitted
    let initialBallotsTotals: {String: UInt64} = getBallotTotals()

    for index, account in accounts {
        // Add an empty Ballot to each account
        txResult = executeTransaction(
            mintBallotToAccountTx,
            [account.address],
            deployer
        )

        Test.expect(txResult, Test.beSucceeded())

        // Increment the event counter
        eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1

        // Capture the ballotMinted event to extract the elements to populate the ballots dictionary
        ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)

        ballotMintedEvent = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

        ballots[account.address] = ballotMintedEvent!._ballotId
    }

    // All done. Try to get the option for each of the accounts that got a Ballot and check that it is nil, the default value, since these have't been cast yet.
    for account in accounts {
        let tempOwnerControlEntry: ownerControlEntry = getOwnerControlEntry(ballotId: ballots[account.address]!, owner: account.address)

        scResult = executeScript(
            getCurrentVoteOptionSc,
            [account.address]
        )

        let currentOption: UInt8? = scResult!.returnValue as! UInt8?

        Test.assertEqual(currentOption, nil)

        // Take the chance to verify that the correct values are set in the OwnerControl
        Test.assertEqual(tempOwnerControlEntry.ballotId!, ballots[account.address]!)
        Test.assertEqual(tempOwnerControlEntry.owner!, account.address)
    }

    if (printLogs) {
        log(
            ballots
        )
    }
    // Validate the events and total ballot amounts
    validateEvents()

    let finalBallotsTotal: {String: UInt64} = getBallotTotals()

    // There should be one ballot minted extra per account
    Test.assertEqual(initialBallotsTotals["minted"]! + UInt64(accounts.length), finalBallotsTotal["minted"]!)
    Test.assertEqual(initialBallotsTotals["submitted"]!, finalBallotsTotal["submitted"]!)
}

access(all) fun testVote() {
    // Take note of the ballot totals
    let initialBallotTotals: {String: UInt64} = getBallotTotals()

    // Set up a dictionary for votes to cast based on the account to vote
    let accountVotes: {Address: UInt8} = {
        account01.address: 1,
        account02.address: 2,
        account03.address: 3,
        account04.address: 4,
        account05.address: 1
    }

    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil

    // Cast the votes but don't submit the Ballots
    for account in accounts {
        txResult = executeTransaction(
            castVoteTx,
            [accountVotes[account.address]!],
            account
        )
    }

    // Validate that the votes were properly cast
    for account in accounts {
        scResult = executeScript(
            getCurrentVoteOptionSc,
            [account.address]
        )

        let currentOption: UInt8? = scResult!.returnValue as! UInt8?

        Test.assertEqual(currentOption!, accountVotes[account.address]!)
    }

    // The Ballot totals should not have changed at all
    let finalBallotTotals: {String: UInt64} = getBallotTotals()

    Test.assertEqual(initialBallotTotals["minted"]!, finalBallotTotals["minted"]!)
    Test.assertEqual(initialBallotTotals["submitted"]!, finalBallotTotals["submitted"]!)

}

// Basically a repeat from the previous test, using a different vote vector
access(all) fun testReVote() {
    // Take note of the initial ballot totals
    let initialBallotTotals: {String: UInt64} = getBallotTotals()

    // NOTE: Account04 was set to 0 (the default value) on purpose. The idea is to trigger a revoke when submitting it later on
    let newAccountVotes: {Address: UInt8?} = {
        account01.address: 3,
        account02.address: 1,
        account03.address: 2,
        account04.address: nil,
        account05.address: 4
    }

    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil

    // Re-cast the new votes
    for account in accounts {
        txResult = executeTransaction(
            castVoteTx,
            [newAccountVotes[account.address]!],
            account
        )

        Test.expect(txResult, Test.beSucceeded())
    }

    // Validate that the options were set properly
    for account in accounts {
        scResult = executeScript(
            getCurrentVoteOptionSc,
            [account.address]
        )

        let currentOption: UInt8? = scResult!.returnValue as! UInt8?

        Test.assertEqual(currentOption, newAccountVotes[account.address]!)
    }

    // Check that no changes happened in the Ballot totals
    let finalBallotTotals: {String: UInt64} = getBallotTotals()

    Test.assertEqual(initialBallotTotals["minted"]!, finalBallotTotals["minted"]!)
    Test.assertEqual(initialBallotTotals["submitted"]!, finalBallotTotals["submitted"]!)
}

access(all) fun testSubmitBallot() {
    // Grab a reference to the ballot totals, as usual
    let initialBallotTotals: {String: UInt64} = getBallotTotals()
    var txResult: Test.TransactionResult? = nil
    var tempOwnerControlEntry: ownerControlEntry? = nil

    // Submit the Ballots
    for account in accounts {
        txResult = executeTransaction(
            submitBallotTx,
            [],
            account
        )

        Test.expect(txResult, Test.beSucceeded())

        // Check that, after submission, the OwnerControl object was cleaned. Clean the ballots dictionary as well
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballots[account.address]!, owner: account.address)

        Test.assertEqual(tempOwnerControlEntry!.ballotId, nil)
        Test.assertEqual(tempOwnerControlEntry!.owner, nil)
    }

    // The previous cycle should have incremented the BallotSubmitted events by 4, the BallotRevoked, BallotBurned, and ResourceDestroyed events by 1. Check it
    eventNumberCount[ballotSubmittedEventType] = eventNumberCount[ballotSubmittedEventType]! + 4
    eventNumberCount[ballotRevokedEventType] = eventNumberCount[ballotRevokedEventType]! + 1
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 1
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 1

    validateEvents()

    // Grab the Ballot totals at the end of this. If all went well, I should have one less minted (the one from account04 that was revoked) and 4 more in the submitted
    let finalBallotTotals: {String: UInt64} = getBallotTotals()

    Test.assertEqual(initialBallotTotals["minted"]! - 1, finalBallotTotals["minted"]!)
    Test.assertEqual(initialBallotTotals["submitted"]! + 4, finalBallotTotals["submitted"]!)
}

// This function mints a new Ballot into every account, re-votes according to some vote vector and submits the whole thing. This test uses transaction "submit_ballot_to_ballot_box" to do the whole thing in one sitting
access(all) fun testReSubmitBallot() {
    // Grab the Ballot totals at this point
    let initialBallotTotals: {String: UInt64} = getBallotTotals()

    var txResult: Test.TransactionResult? = nil
    var tempOwnerControlEntry: ownerControlEntry? = nil
    var ballotMintedEvent: VoteBoothST.BallotMinted? = nil
    var ballotModifiedEvent: VoteBoothST.BallotModified? = nil

    for account in accounts {
        // Mint a new Ballot into each account
        txResult = executeTransaction(
            mintBallotToAccountTx,
            [account.address],
            deployer
        )

        Test.expect(txResult, Test.beSucceeded())

        // Account for the new BallotMinted event
        eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1

        ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)

        ballotMintedEvent = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

        // Add the new Ballot to the newBallots dictionary
        ballotsToRevoke[ballotMintedEvent!._voterAddress] = ballotMintedEvent!._ballotId

        // Check that the OwnerControl was properly updated
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballotMintedEvent!._ballotId, owner: ballotMintedEvent!._voterAddress)

        Test.assertEqual(tempOwnerControlEntry!.ballotId!, ballotsToRevoke[account.address]!)
        Test.assertEqual(tempOwnerControlEntry!.owner!, account.address)
    }

    // Check that the Event count is still consistent
    validateEvents()

    // Set up the new vote vector but with only one option for all in this case
    let newAccountVotes: {Address: UInt8} = {
        account01.address: 1,
        account02.address: 1,
        account03.address: 1,
        account04.address: 1,
        account05.address: 1
    }

    for account in accounts {
        txResult = executeTransaction(
            submitBallotToBallotBoxTx,
            [newAccountVotes[account.address]],
            account
        )

        Test.expect(txResult, Test.beSucceeded())

        // This "new" submission is going to trigger a BallotSubmitted only for account04, because its ballot was revoked before. Every other submission is going to trigger a BallotModified instead
        if (account.address == account04.address) {
            eventNumberCount[ballotSubmittedEventType] = eventNumberCount[ballotSubmittedEventType]! + 1
        }
        else {
            // Account for the BallotModified event in this case and validate its arguments
            eventNumberCount[ballotModifiedEventType] = eventNumberCount[ballotModifiedEventType]! + 1

            ballotModifiedEvents = Test.eventsOfType(ballotModifiedEventType)

            ballotModifiedEvent = ballotModifiedEvents[ballotModifiedEvents.length - 1] as! VoteBoothST.BallotModified

            Test.assertEqual(ballotModifiedEvent!._voterAddress, account.address)
            Test.assertEqual(ballotModifiedEvent!._newBallotId, ballotsToRevoke[account.address]!)
            Test.assertEqual(ballotModifiedEvent!._oldBallotId, ballots[account.address]!)
        }
    }

    // The Ballot submitted for all accounts except account04 replaced an existing Ballot. This means that the old Ballot was burned in each of the other 4 account. Take this into account
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 4
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 4

    // Validate events
    validateEvents()

    let finalBallotTotals: {String: UInt64} = getBallotTotals()
    // I'm going to get 5 more ballots minted from the initial part, but 4 of these are going to replace previously submitted ballots, which are going to be burned. So in total I should have only 1 more minted
    Test.assertEqual(initialBallotTotals["minted"]! + 1, finalBallotTotals["minted"]!)
    // The same reasoning applies to the total submitted. Only one more to account for the one previously revoked from account04
    Test.assertEqual(initialBallotTotals["submitted"]! + 1, finalBallotTotals["submitted"]!)
}

access(all) fun testRevokeBallot() {
    // As usual, start by taking note of all the Ballot totals
    let initialBallotTotals: {String: UInt64} = getBallotTotals()

    // To revoke the previously submitted Ballots, I need to mint another round to each of the accounts
    var txResult: Test.TransactionResult? = nil
    var tempOwnerControlEntry: ownerControlEntry? = nil
    var ballotMintedEvent: VoteBoothST.BallotMinted? = nil
    var ballotRevokedEvent: VoteBoothST.BallotRevoked? = nil

    for account in accounts {
        // First, just to be sure, try to submit a Ballot without having none in the VoteBox. It is expected that it fails
        txResult = executeTransaction(
            submitBallotTx,
            [],
            account
        )

        Test.expect(txResult, Test.beFailed())

        // Proceeded with minting the Ballots to use in the revoking process
        txResult = executeTransaction(
            mintBallotToAccountTx,
            [account.address],
            deployer
        )

        Test.expect(txResult, Test.beSucceeded())

        // Check that the new Ballot parameters were properly added to the OwnerControl resource
        eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
        ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
        ballotMintedEvent = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted

        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballotMintedEvent!._ballotId, owner: ballotMintedEvent!._voterAddress)

        Test.assertEqual(ballotMintedEvent!._ballotId, tempOwnerControlEntry!.ballotId!)
        Test.assertEqual(tempOwnerControlEntry!.owner!, account.address)

        // Proceed to revoke the previously submitted Ballot by submitting this one without casting any actual vote, since these are minted with the default option set
        txResult = executeTransaction(
            submitBallotTx,
            [],
            account
        )

        Test.expect(txResult, Test.beSucceeded())

        // Ballot was revoked. Test that the OwnerControl parameters were set to nil
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballotMintedEvent!._ballotId, owner: ballotMintedEvent!._voterAddress)

        Test.assertEqual(tempOwnerControlEntry!.ballotId, nil)
        Test.assertEqual(tempOwnerControlEntry!.owner, nil)

        // Adjust the event counters. I should have two BallotBurned and ResourceDestroyed, and one BallotRevoked per account
        eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + 2
        eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + 2
        eventNumberCount[ballotRevokedEventType] = eventNumberCount[ballotRevokedEventType]! + 1

        // Refresh the BallotRevoked event queue
        ballotRevokedEvents = Test.eventsOfType(ballotRevokedEventType)

        // Grab the last one and validate that the Ballot revoked data in the event matches the data stored previously for the submitted Ballots
        ballotRevokedEvent = ballotRevokedEvents[ballotRevokedEvents.length - 1] as! VoteBoothST.BallotRevoked

        Test.assertEqual(ballotsToRevoke[account.address]!, ballotRevokedEvent!._ballotId!)
        Test.assertEqual(account.address, ballotRevokedEvent!._voterAddress)
    }

    // Validate Events at this point
    validateEvents()

    // And the Ballot totals at the end of this one
    let finalBallotTotals: {String: UInt64} = getBallotTotals()

    // The previous loop, per account, adds +1 to the total minted, but then adds -2 due to the Ballots being burned when they are revoked, therefore, the totals minted should have been reduced by 1 per account
    Test.assertEqual(initialBallotTotals["minted"]! - UInt64(accounts.length), finalBallotTotals["minted"]!)

    // The total submitted suffers from the same deficit: -1 per account to account for the Ballot revoked
    Test.assertEqual(initialBallotTotals["submitted"]! - UInt64(accounts.length), finalBallotTotals["submitted"]!)

    // Since I cleaned up all the Ballots in storage, the totals at the end should all be 0
    Test.assertEqual(finalBallotTotals["minted"]!, 0 as UInt64)
    Test.assertEqual(finalBallotTotals["submitted"]!, 0 as UInt64) 
}

// Just to finish this up, this function mints a new Ballot into each account and then destroy the VoteBoxes, just to trigger the BurnBox mechanics
access(all) fun testDestroyVoteBoxes() {
    // Grab the Ballot totals. After this one, they all should retain their 0 totals
    let initialBallotTotals: {String: UInt64} = getBallotTotals()

    var ballotMintedEvent: VoteBoothST.BallotMinted? = nil
    var ballotSetToBurnEvent: VoteBoothST.BallotSetToBurn? = nil
    var tempOwnerControlEntry: ownerControlEntry? = nil
    var txResult: Test.TransactionResult? = nil

    for account in accounts {
        // Start by minting a new Ballot into each VoteBox
        txResult = executeTransaction(
            mintBallotToAccountTx,
            [account.address],
            deployer
        )

        Test.expect(txResult, Test.beSucceeded())

        // Refresh the ballots dictionary with the new Ballot data
        eventNumberCount[ballotMintedEventType] = eventNumberCount[ballotMintedEventType]! + 1
        ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
        ballotMintedEvent = ballotMintedEvents[ballotMintedEvents.length - 1] as! VoteBoothST.BallotMinted
        
        ballots[account.address] = ballotMintedEvent!._ballotId

        // Check the consistency of the OwnerControl resource
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballots[account.address]!, owner: account.address)

        Test.assertEqual(tempOwnerControlEntry!.ballotId!, ballots[account.address]!)
        Test.assertEqual(tempOwnerControlEntry!.owner!, account.address)

        // All good. Destroy the VoteBox for this account
        txResult = executeTransaction(
            destroyVoteBoxTx,
            [],
            account
        )

        Test.expect(txResult, Test.beSucceeded())

        // Adjust the event counters
        eventNumberCount[voteBoxDestroyedEventType] = eventNumberCount[voteBoxDestroyedEventType]! + 1
        eventNumberCount[ballotSetToBurnEventType] = eventNumberCount[ballotSetToBurnEventType]! + 1

        // Refresh the BallotSetToBurn event queue, grab the last one and make sure its parameter match the ones set in the ballots dictionary
        ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)
        ballotSetToBurnEvent = ballotSetToBurnEvents[ballotSetToBurnEvents.length - 1] as! VoteBoothST.BallotSetToBurn

        Test.assertEqual(ballotSetToBurnEvent!._ballotId, ballots[account.address]!)
        Test.assertEqual(ballotSetToBurnEvent!._voterAddress, account.address)

        // Ensure that the OwnerControl resource is still consistent
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballots[account.address]!, owner: account.address)

        Test.assertEqual(tempOwnerControlEntry!.ballotId!, ballots[account.address]!)
        Test.assertEqual(tempOwnerControlEntry!.owner!, account.address)
    }
    // Validate events at this point
    validateEvents()

    // Check how many Ballots are set to be burn and confirm that is the same number as accounts considered thus far
    var scResult: Test.ScriptResult = executeScript(
        getHowManyBallotsToBurnSc,
        [deployer.address]
    )

    let ballotsSetToBurn: Int = scResult.returnValue as! Int

    Test.assertEqual(ballotsSetToBurn, accounts.length)

    // All good. Set the Ballots in the BurnBox for destruction and validate the events and counters
    txResult = executeTransaction(
        burnBallotFromBurnBoxTx,
        [],
        deployer
    )

    Test.expect(txResult, Test.beSucceeded())

    // This last transaction should have incremented the BallotBurned and ResourceDestroyed events by the number of Ballots burned before. Check it
    eventNumberCount[ballotBurnedEventType] = eventNumberCount[ballotBurnedEventType]! + ballotsSetToBurn
    eventNumberCount[resourceDestroyedEventType] = eventNumberCount[resourceDestroyedEventType]! + ballotsSetToBurn

    validateEvents()

    // Check that the BallotBurned events match the current values for the ballots dictionary
    let ballotOwners: [Address] = ballots.keys
    let ballotIds: [UInt64] = ballots.values
    var ballotBurnedEvent: VoteBoothST.BallotBurned? = nil

    for index, account in accounts {
        ballotBurnedEvent = ballotBurnedEvents[ballotBurnedEvents.length - 1 - index] as! VoteBoothST.BallotBurned

        Test.assert(ballotOwners.contains(ballotBurnedEvent!._voterAddress!))
        Test.assert(ballotIds.contains(ballotBurnedEvent!._ballotId!))

        // Test that burning the Ballot cleared the relevant parameter in the OwnerControl resource
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballots[account.address]!, owner: account.address)

        Test.assertEqual(tempOwnerControlEntry!.ballotId, nil)
        Test.assertEqual(tempOwnerControlEntry!.owner, nil)
    }

    // Finish this by comparing the totals among themselves and with the expected value
    let finalBallotTotals: {String: UInt64} = getBallotTotals()

    // Basically, this process burned every ballot minted, so the totals should have remained stable and 0
    Test.assertEqual(initialBallotTotals["minted"]!, finalBallotTotals["minted"]!)
    Test.assertEqual(initialBallotTotals["submitted"]!, finalBallotTotals["submitted"]!)
    Test.assertEqual(finalBallotTotals["minted"]!, 0 as UInt64)
    Test.assertEqual(finalBallotTotals["submitted"]!, 0 as UInt64)
}

// TODO: Eligibility Module
// TODO: Tally Contract
// TODO: Implement the Verifiability modules (check notes for the actual idea)
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

    // Create a new Ballots dictionary towards being able to compare with the old one (still active)
    var newBallots: {Address: UInt64} = {}

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
        newBallots[ballotMintedEvent!._voterAddress] = ballotMintedEvent!._ballotId

        // Check that the OwnerControl was properly updated
        tempOwnerControlEntry = getOwnerControlEntry(ballotId: ballotMintedEvent!._ballotId, owner: ballotMintedEvent!._voterAddress)

        Test.assertEqual(tempOwnerControlEntry!.ballotId!, newBallots[account.address]!)
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
            Test.assertEqual(ballotModifiedEvent!._newBallotId, newBallots[account.address]!)
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

access(all) fun _testRevokeBallot() {
    
}


// TODO: Modify Ballots (Vote)
// TODO: Multiple Vote Casting
// TODO: Eligibility Module
// TODO: Tally Contract
// TODO: Implement the Verifiability modules (check notes for the actual idea)
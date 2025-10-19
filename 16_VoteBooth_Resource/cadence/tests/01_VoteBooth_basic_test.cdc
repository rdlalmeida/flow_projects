import Test
import BlockchainHelpers
import "BallotStandard"
import "ElectionStandard"
import "VoteBoxStandard"
import "VoteBooth"

// EVENTS
// BallotStandard.cdc
access(all) let ballotCreatedEventType: Type = Type<BallotStandard.BallotCreated>()
access(all) let ballotBurnedEventType: Type = Type<BallotStandard.BallotBurned>()

// ElectionStandard.cdc
access(all) let ballotSubmittedEventType: Type = Type<ElectionStandard.BallotSubmitted>()
access(all) let ballotReplacedEventType: Type = Type<ElectionStandard.BallotReplaced>()
access(all) let ballotRevokedEventType: Type = Type<ElectionStandard.BallotRevoked>()
access(all) let ballotsWithdrawnEventType: Type = Type<ElectionStandard.BallotsWithdrawn>()
access(all) let electionCreatedEventType: Type = Type<ElectionStandard.ElectionCreated>()
access(all) let electionDestroyedEventType: Type = Type<ElectionStandard.ElectionDestroyed>()
access(all) let nonNilResourceDestroyedEventType: Type = Type<ElectionStandard.NonNilResourceReturned>()

// VoteBoxStandard.cdc
access(all) let voteBoxCreatedEventType: Type = Type<VoteBoxStandard.VoteBoxCreated>()
access(all) let voteBoxDestroyedEventType: Type = Type<VoteBoxStandard.VoteBoxDestroyed>()

// VoteBooth.cdc
access(all) let electionsDestroyedEventType: Type = Type<VoteBooth.ElectionsDestroyed>()

access(all) var eventNumberCount: {Type: Int} = {
    ballotCreatedEventType: 0,
    ballotBurnedEventType: 0,
    ballotSubmittedEventType: 0,
    ballotReplacedEventType: 0,
    ballotsWithdrawnEventType: 0,
    electionCreatedEventType: 0,
    electionDestroyedEventType: 0,
    nonNilResourceDestroyedEventType: 0,
    voteBoxCreatedEventType: 0,
    voteBoxDestroyedEventType: 0,
    electionsDestroyedEventType: 0
}

access(all) var ballotCreatedEvents: [AnyStruct] = []
access(all) var ballotBurnedEvents: [AnyStruct] = []
access(all) var ballotSubmittedEvents: [AnyStruct] = []
access(all) var ballotReplacedEvents: [AnyStruct] = []
access(all) var ballotsWithdrawnEvents: [AnyStruct] = []
access(all) var electionCreatedEvents: [AnyStruct] = []
access(all) var electionDestroyedEvents: [AnyStruct] = []
access(all) var nonNilResourceReturnedEvents: [AnyStruct] = []
access(all) var voteBoxCreatedEvents: [AnyStruct] = []
access(all) var voteBoxDestroyedEvents: [AnyStruct] = []
access(all) var electionsDestroyedEvents: [AnyStruct] = []

access(all) fun validateEvents() {
    ballotCreatedEvents = Test.eventsOfType(ballotCreatedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    ballotSubmittedEvents = Test.eventsOfType(ballotSubmittedEventType)
    ballotReplacedEvents = Test.eventsOfType(ballotReplacedEventType)
    ballotsWithdrawnEvents = Test.eventsOfType(ballotsWithdrawnEventType)
    electionCreatedEvents = Test.eventsOfType(electionCreatedEventType)
    electionDestroyedEvents = Test.eventsOfType(electionDestroyedEventType)
    nonNilResourceReturnedEvents = Test.eventsOfType(nonNilResourceDestroyedEventType)
    voteBoxCreatedEvents = Test.eventsOfType(voteBoxCreatedEventType)
    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    electionsDestroyedEvents = Test.eventsOfType(electionsDestroyedEventType)

    Test.assertEqual(ballotCreatedEvents.length, eventNumberCount[ballotCreatedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(ballotSubmittedEvents.length, eventNumberCount[ballotSubmittedEventType]!)
    Test.assertEqual(ballotReplacedEvents.length, eventNumberCount[ballotReplacedEventType]!)
    Test.assertEqual(ballotsWithdrawnEvents.length, eventNumberCount[ballotsWithdrawnEventType]!)
    Test.assertEqual(electionCreatedEvents.length, eventNumberCount[electionCreatedEventType]!)
    Test.assertEqual(electionDestroyedEvents.length, eventNumberCount[electionDestroyedEventType]!)
    Test.assertEqual(nonNilResourceReturnedEvents.length, eventNumberCount[nonNilResourceDestroyedEventType]!)
    Test.assertEqual(voteBoxCreatedEvents.length, eventNumberCount[voteBoxCreatedEventType]!)
    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(electionsDestroyedEvents.length, eventNumberCount[electionsDestroyedEventType]!)
}

// TRANSACTIONS
access(all) let createElectionTx: String = "../transactions/01_create_election.cdc"
access(all) let createVoteBoxTx: String = "../transactions/02_create_vote_box.cdc"
access(all) let createBallotTx: String = "../transactions/03_create_ballot.cdc"
access(all) let castBallotTx: String = "../transactions/04_cast_ballot.cdc"
access(all) let submitBallotTx: String = "../transactions/05_submit_ballot.cdc"

// SCRIPTS
access(all) let testContractConsistencySc: String = "../scripts/01_test_contract_consistency.cdc"
access(all) let getActiveElectionsSc: String = "../scripts/02_get_active_elections.cdc"
access(all) let getElectionNameSc: String = "../scripts/03_get_election_name.cdc"
access(all) let getElectionBallotSc: String = "../scripts/04_get_election_ballot.cdc"
access(all) let getElectionOptionsSc: String = "../scripts/05_get_election_options.cdc"
access(all) let getElectionIdSc: String = "../scripts/06_get_election_id.cdc"
access(all) let getElectionPublicEncryptionKeySc: String = "../scripts/07_get_public_encryption_key.cdc"
access(all) let getElectionCapabilitySc: String = "../scripts/08_get_election_capability.cdc"
access(all) let getElectionTotalsSc: String = "../scripts/09_get_election_totals.cdc"
access(all) let getElectionStoragePathSc: String = "../scripts/10_get_election_storage_path.cdc"
access(all) let getElectionPublicPathSc: String = "../scripts/11_get_election_public_path.cdc"
access(all) let getElectionsListSc: String = "../scripts/12_get_elections_list.cdc"
access(all) let getBallotOptionSc: String = "../scripts/13_get_ballot_option.cdc"

// PATHS
// VoteBoxStandard.cdc
access(all) let expectedVoteBoxStoragePath: StoragePath = /storage/voteBox
access(all) let expectedVoteBoxPublicPath: PublicPath = /public/voteBox

// VoteBooth.cdc
access(all) let expectedVoteBoothPrinterAdminStoragePath: StoragePath = /storage/VoteBoothPrinterAdmin
access(all) let expectedElectionIndexStoragePath: StoragePath = /storage/ElectionIndex
access(all) let expectedElectionIndexPublicPath: PublicPath = /public/ElectionIndex

// CUSTOM INPUT ARGUMENTS
access(all) let electionNames: [String] = ["A. Bullfights", "B. Coconut Cake", "C. Basketball"]
access(all) let electionBallots: [String] = [
    "A. What should happen to bullfighters once Portugal bans this stupid practice?",
    "B. What is the best frosting for coconut cake?",
    "C. Which NBA team is going to win the 2025-26 championship?"
]
access(all) let electionOptions: [{UInt8: String}] = [
    {
        1: "Starve them to death", 
        2: "Bundle them in a shipping container and drop it into the ocean", 
        3: "Enslave and make them build animal shelters until dead", 
        4: "Process them into animal feed",
        5: "Tax them into poverty and force them to clean animal stalls for food"
    },
    {
        1: "Powdered sugar",
        2: "Shredded coconut",
        3: "Tempered dark chocolate",
        4: "Butter-based frosting",
        5: "Nothing. Leave it as is."
    },
    {
        1: "Minnesota Timber Wolves",
        2: "Oklahoma City Thunder",
        3: "New York Knicks",
        4: "Cleveland Cavaliers",
        5: "None of the above"
    }
]

access(all) let electionPublicEncryptionKeys: [[UInt8]] = [
    [87, 174, 84, 18, 106, 155, 246, 129, 83, 78, 24, 168, 183, 53, 39, 121, 60, 186, 137, 156, 247, 185, 9, 137, 100, 151, 208, 113, 59, 191, 26, 118],
    [51, 171, 190, 97, 148, 77, 139, 219, 238, 108, 187, 103, 11, 17, 101, 98, 82, 99, 198, 155, 229, 236, 199, 71, 83, 213, 183, 240, 193, 220, 78, 239],
    [2, 164, 77, 118, 115, 138, 60, 142, 115, 146, 41, 115, 4, 36, 56, 23, 183, 225, 212, 85, 28, 203, 62, 60, 162, 113, 133, 116, 215, 163, 53, 79]
]

access(all) let electionStoragePaths: [StoragePath] = [
    /storage/Election01,
    /storage/Election02,
    /storage/Election03
]

access(all) let electionPublicPaths: [PublicPath] = [
    /public/Election01,
    /public/Election02,
    /public/Election03
]

// OTHER VARIABLES
access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000007)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let account04: Test.TestAccount = Test.createAccount()
access(all) let account05: Test.TestAccount = Test.createAccount()

access(all) let accounts: [Test.TestAccount] = [account01, account02, account03, account04, account05]

access(all) let verbose: Bool = true

// Simple array to keep the electionIds of the active Election resources
access(all) var activeElectionIds: [UInt64] = []

// And this dictionary keeps a list of open Elections in a {electionId:String} format.
access(all) var electionList: {UInt64: String} = {}

// Use this index to define the selected Election from a set of available ones
access(all) var selectedElectionIndex: Int = 1
access(all) var selectedElectionId: UInt64 = 0

// The default option set to any newly minted Ballot
access(all) let defaultBallotOption: String = "default"

// And these variables as set points for the selected Election above
access(all) var selectedElectionName: String = ""
access(all) var selectedElectionBallot: String = ""
access(all) var selectedElectionOptions: {UInt8: String} = {}
access(all) var selectedElectionPublicEncryptionKey: [UInt8] = []
access(all) var selectedElectionCapability: Capability<&{ElectionStandard.ElectionPublic}>? = nil

// This is just a handy way to have the voters represented by each of the test account easily
// This set represents the first round of voting
access(all) let voterOptions: {Address: String} = {
    account01.address: electionOptions[selectedElectionIndex][3]!,
    account02.address: electionOptions[selectedElectionIndex][5]!,
    account03.address: electionOptions[selectedElectionIndex][2]!,
    account04.address: electionOptions[selectedElectionIndex][3]!,
    account05.address: electionOptions[selectedElectionIndex][1]!
}

// And this similar set is used to change the options on already cast Ballots, just to confirm that it works. I'm essentially inverting the order from 
// initial set
access(all) let moreVoterOptions: {Address: String} = {
    account01.address: electionOptions[selectedElectionIndex][1]! ,
    account02.address: electionOptions[selectedElectionIndex][3]!,
    account03.address: electionOptions[selectedElectionIndex][2]!,
    account04.address: electionOptions[selectedElectionIndex][5]!,
    account05.address: electionOptions[selectedElectionIndex][3]!
}

access(all) fun setup() {
    var err: Test.Error? = Test.deployContract(
        name: "BallotStandard",
        path: "../contracts/BallotStandard.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "ElectionStandard",
        path: "../contracts/ElectionStandard.cdc",
        arguments: []
    )

    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "VoteBoxStandard",
        path: "../contracts/VoteBoxStandard.cdc",
        arguments: []
    )

    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "VoteBooth",
        path: "../contracts/VoteBooth.cdc",
        arguments: [verbose]
    )

    Test.expect(err, Test.beNil())

    // Printout the addresses of the test accounts for reference
    if (verbose) {
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
}

/**
    Test that all contracts were deployed into the same account. I've created a whole script just to do this.
**/
access(all) fun testDeployerAddress() {
    let scResult: Test.ScriptResult = executeScript(
        testContractConsistencySc,
        []
    )

    Test.expect(scResult, Test.beSucceeded())

    let contractConsistency: Bool = scResult.returnValue as! Bool

    Test.assert(contractConsistency)
}

/**
    Test that the storage and public paths defined at the contract levels are as expected.
**/
access(all) fun testContractPaths() {
    Test.assertEqual(expectedElectionIndexStoragePath, VoteBooth.electionIndexStoragePath)
    Test.assertEqual(expectedElectionIndexPublicPath, VoteBooth.electionIndexPublicPath)
    Test.assertEqual(expectedVoteBoothPrinterAdminStoragePath, VoteBooth.voteBoothPrinterAdminStoragePath)
    Test.assertEqual(expectedVoteBoxStoragePath, VoteBoxStandard.voteBoxStoragePath)
    Test.assertEqual(expectedVoteBoxPublicPath, VoteBoxStandard.voteBoxPublicPath)
}

/**
    Test the creation of a new Election resource with parameters pre-defined
**/
access(all) fun testCreateElection() {
    // I'm going to create three Elections using the parameter arrays defined in this test script
    var txResult: Test.TransactionResult? = nil

    for index, element in electionNames {
        txResult = executeTransaction(
            createElectionTx, 
            [
                electionNames[index], 
                electionBallots[index],
                electionOptions[index],
                electionPublicEncryptionKeys[index],
                electionStoragePaths[index],
                electionPublicPaths[index]
            ],
            deployer
        )

        Test.expect(txResult, Test.beSucceeded())
    }

    // I should have as many ElectionCreated events as the number of Election created in the cycle above. Check it
    eventNumberCount[electionCreatedEventType] = eventNumberCount[electionCreatedEventType]! + electionNames.length
    // Validate that the event count is still consistent
    validateEvents()

    // Grab all the electionIds for the active Elections created above
    var scResult: Test.ScriptResult = executeScript(
        getActiveElectionsSc,
        [nil]
    )

    Test.expect(scResult, Test.beSucceeded())

    // Fill out the activeElectionIds array
    activeElectionIds = scResult.returnValue as! [UInt64]

    // Make sure that all the electionIds and electionNames in the ElectionCreated events emitted are contained in the set of electionIds and electionNames
    var eventElectionId: UInt64 = 0
    var eventElectionName: String = ""

    // TODO: REPEAT THIS ANALYSIS FOR THE REST OF THE EVENT LOGIC
    // Limit the analysis of the electionCreatedEvents to the last ones only
    for electionCreatedEvent in electionCreatedEvents.slice(from: (electionCreatedEvents.length - electionNames.length), upTo: (electionCreatedEvents.length)) {
        let normalisedEvent:ElectionStandard.ElectionCreated = electionCreatedEvent as! ElectionStandard.ElectionCreated
        
        eventElectionId = normalisedEvent._electionId
        eventElectionName = normalisedEvent._electionName

        Test.assert(activeElectionIds.contains(eventElectionId), 
            message: "ERROR: Got an ElectionCreated event with electionId "
            .concat(eventElectionId.toString())
            .concat(" but this Id is not among the activeElectionIds!")
        )

        Test.assert(electionNames.contains(eventElectionName),
            message: "ERROR: Got an ElectionCreated with electionName "
            .concat(eventElectionName)
            .concat(" but this name is not among the ElectionNames! ")
        )
    }

    scResult = executeScript(
        getElectionsListSc,
        []
    )

    Test.expect(scResult, Test.beSucceeded())

    // And now for the election list
    electionList = scResult.returnValue as! {UInt64: String}

    // Validate that this dictionary is consistent
    Test.assert(electionList.length == electionNames.length)

    for electionId in electionList.keys {
        // Test that the electionIds returned as keys are in the activeElectionIds set
        Test.assert(activeElectionIds.contains(electionId))

        // And test that the names returned are also inside the array used to create them.
        Test.assert(electionNames.contains(electionList[electionId]!))
    }

    // Check that we got the same number of electionIds back
    Test.assertEqual(activeElectionIds.length, electionNames.length)

    // Use a loop to validate each parameter set in the createElection transaction
    var electionName: String = ""
    var electionBallot: String = ""
    var electionOption: {UInt8: String} = {}
    var electionId: UInt64 = 0
    var electionPublicKey: [UInt8] = []
    var electionCapability: Capability? = nil
    var electionTotals: {String: UInt} = {}
    var electionStoragePath: StoragePath? = nil
    var electionPublicPath: PublicPath? = nil

    // Set the electionId for the Election in question
    selectedElectionId = activeElectionIds[selectedElectionIndex]

    for activeElectionId in activeElectionIds {
        // Start with the election names
        scResult = executeScript(
            getElectionNameSc,
            [activeElectionId, nil]
        )

        Test.expect(scResult, Test.beSucceeded())

        // Extract the name from the script result
        electionName = scResult.returnValue as! String

        // Because Cadence does not guarantees the order in which the electionIds were returned, I cannot compare these based on indexes.
        // The next best thing is to ensure that the item returned exits in the set used to construct the Election in the first place.
        Test.assert(electionNames.contains(electionName))

        // Repeat for the rest
        // Election Ballot
        scResult = executeScript(
            getElectionBallotSc,
            [activeElectionId, nil]
        )

        Test.expect(scResult, Test.beSucceeded())

        electionBallot = scResult.returnValue as! String

        Test.assert(electionBallots.contains(electionBallot))

        // Election Options
        scResult = executeScript(
            getElectionOptionsSc,
            [activeElectionId, nil]
        )
        Test.expect(scResult, Test.beSucceeded())
        electionOption = scResult.returnValue as! {UInt8: String}
        Test.assert(electionOptions.contains(electionOption))

        // Election Id
        scResult = executeScript(
            getElectionIdSc,
            [activeElectionId, nil]
        )
        Test.expect(scResult, Test.beSucceeded())
        electionId = scResult.returnValue as! UInt64
        Test.assert(activeElectionIds.contains(electionId))

        // Public Encryption Key
        scResult = executeScript(
            getElectionPublicEncryptionKeySc,
            [activeElectionId, nil]
        )
        Test.expect(scResult, Test.beSucceeded())
        electionPublicKey = scResult.returnValue as! [UInt8]
        Test.assert(electionPublicEncryptionKeys.contains(electionPublicKey))

        // Election Capability
        scResult = executeScript(
            getElectionCapabilitySc,
            [activeElectionId, nil]
        )
        Test.expect(scResult, Test.beSucceeded())
        // If the next force cast succeeds, thats test enough
        electionCapability = scResult.returnValue as! Capability<&{ElectionStandard.ElectionPublic}>

        // Election Ballot totals
        scResult = executeScript(
            getElectionTotalsSc,
            [activeElectionId, nil]
        )
        Test.expect(scResult, Test.beSucceeded())
        electionTotals = scResult.returnValue as! {String: UInt}
        Test.assert(electionTotals["totalBallotsMinted"] == 0)
        Test.assert(electionTotals["totalBallotsSubmitted"] == 0)

        // Election Storage Path
        scResult = executeScript(
            getElectionStoragePathSc,
            [activeElectionId]
        )
        Test.expect(scResult, Test.beSucceeded())
        electionStoragePath = scResult.returnValue as! StoragePath
        Test.assert(electionStoragePaths.contains(electionStoragePath!))

        // Election Public Path
        scResult = executeScript(
            getElectionPublicPathSc,
            [activeElectionId]
        )
        Test.expect(scResult, Test.beSucceeded())
        electionPublicPath = scResult.returnValue as! PublicPath
        Test.assert(electionPublicPaths.contains(electionPublicPath!))

        // At the end of this cycle, check if the activeElectionId matches the selectedElectionId and, if so, set the selected set of parameters
        if (selectedElectionId == activeElectionId) {
            selectedElectionName = electionName
            selectedElectionBallot = electionBallot
            selectedElectionOptions = electionOption
            selectedElectionId = electionId
            selectedElectionPublicEncryptionKey = electionPublicKey
            selectedElectionCapability = electionCapability as! Capability<&{ElectionStandard.ElectionPublic}>
        }
    }

}

/**
    Test the creation of a new VoteBox resource into each of the 5 test accounts
**/
access(all) fun testCreateVoteBox() {
    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil

    for account in accounts {
        // Create a new VoteBox resource in each of the user accounts
        txResult = executeTransaction(
            createVoteBoxTx,
            [],
            account
        )

        Test.expect(txResult, Test.beSucceeded())
    }

    // Validate the VoteBoxCreated events. I should have one per account used
    eventNumberCount[voteBoxCreatedEventType] = eventNumberCount[voteBoxCreatedEventType]! + accounts.length
    validateEvents()

    var activeBallots: Int = 0
    // For each voter, grab the list of activeBallots out of their VoteBoxes. Each should be empty
    for account in accounts {
        scResult = executeScript(
            getActiveElectionsSc,
            [account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        // Get the active number of elections for each VoteBox and each account
        activeBallots = (scResult!.returnValue as! [UInt64]).length

        // Each should be empty still
        Test.assert(activeBallots == 0)
    }
}

/**
    This test function tries to print a brand new Ballot for Election #1 into each VoteBox in each test account.
**/
access(all) fun testPrintBallotIntoVoteBox() {
    
    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil
    selectedElectionId = activeElectionIds[selectedElectionIndex]

    var electionName: String = ""
    var electionBallot: String = ""
    var electionOptions: {UInt8: String} = {}
    var electionId: UInt64 = 0
    var electionPublicEncryptionKey: [UInt8] = []
    var electionCapability: Capability? = nil
    var electionTotals: {String: UInt} = {}
    var electionTotalBallotsMinted: UInt = 0
    var electionTotalBallotsSubmitted: UInt = 0

    log(
        "Printing "
        .concat(accounts.length.toString())
        .concat(" Ballots for Election ")
        .concat(activeElectionIds[selectedElectionIndex].toString())
        .concat(": ")
        .concat(electionList[selectedElectionId]!)
    )
    for account in accounts {
        txResult = executeTransaction(
            createBallotTx,
            [selectedElectionId, account.address],
            deployer
        )

        Test.expect(txResult, Test.beSucceeded())
    }

    // Validate BallotCreated events. I should have one per account used
    eventNumberCount[ballotCreatedEventType] = eventNumberCount[ballotCreatedEventType]! + accounts.length
    validateEvents()

    // Do another cycle and check, for each account, if the electionName, electionBallot, etc. matches the selected ones
    // Run the getter scripts of before but providing the account address as inputs to trigger the VoteBox retrieval circuit
    for account in accounts {
        scResult = executeScript(
            getElectionNameSc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        electionName = scResult!.returnValue as! String

        Test.assertEqual(electionName, selectedElectionName)

        scResult = executeScript(
            getElectionBallotSc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        electionBallot = scResult!.returnValue as! String

        Test.assertEqual(electionBallot, selectedElectionBallot)

        scResult = executeScript(
            getElectionOptionsSc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        electionOptions = scResult!.returnValue as! {UInt8: String}

        Test.assertEqual(electionOptions, selectedElectionOptions)

        scResult = executeScript(
            getElectionIdSc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        electionId = scResult!.returnValue as! UInt64

        Test.assertEqual(electionId, selectedElectionId)

        scResult = executeScript(
            getElectionPublicEncryptionKeySc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        electionPublicEncryptionKey = scResult!.returnValue as! [UInt8]

        Test.assertEqual(electionPublicEncryptionKey, selectedElectionPublicEncryptionKey)

        scResult = executeScript(
            getElectionCapabilitySc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        electionCapability = scResult!.returnValue as! Capability<&{ElectionStandard.ElectionPublic}>

        Test.assertEqual(electionCapability, selectedElectionCapability)

        // Validate the election totals, both through the ElectionIndex and through the VoteBox
        scResult = executeScript(
            getElectionTotalsSc,
            [selectedElectionId, nil]
        )

        Test.expect(scResult, Test.beSucceeded())

        electionTotals = scResult!.returnValue as! {String: UInt}

        electionTotalBallotsMinted = electionTotals["totalBallotsMinted"]!
        electionTotalBallotsSubmitted = electionTotals["totalBallotsSubmitted"]!

        // The Election should have a totalBallotsMinted equal to the number of accounts
        Test.assertEqual(Int(electionTotalBallotsMinted), accounts.length)

        // But not the submitted totals, at least not yet. These should still be 0
        Test.assertEqual(Int(electionTotalBallotsSubmitted), 0)

        // Repeat the call, but from the VoteBox reference side
        scResult = executeScript(
            getElectionTotalsSc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        // Update the election totals
        electionTotals = scResult!.returnValue as! {String: UInt}
        electionTotalBallotsMinted = electionTotals["totalBallotsMinted"]!
        electionTotalBallotsSubmitted = electionTotals["totalBallotsSubmitted"]!

        // And test that the same results are consistent from the ones obtained directly from the Election reference.
        Test.assertEqual(Int(electionTotalBallotsMinted), accounts.length)
        Test.assertEqual(Int(electionTotalBallotsSubmitted), 0)
    }
}


/**
    This test function attempts to change the option set in each of the Ballots submitted
**/
access(all) fun testCastBallot() {
    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil
    var oldOption: String = ""
    var newOption: String = ""

    // First, start by confirming that, at this point, the option in each Ballot is still set to "default"
    for account in accounts {
        scResult = executeScript(
            getBallotOptionSc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        oldOption = scResult!.returnValue as! String

        Test.assert(oldOption == defaultBallotOption, 
            message: "Ballot for Election "
            .concat(selectedElectionId.toString())
            .concat(" does not has the default option set. Instead it has: ")
            .concat(oldOption)
        )

        // Set the new option according to what is set in the voterOptions dictionary
        txResult = executeTransaction(
            castBallotTx,
            [selectedElectionId, voterOptions[account.address]!],
            account
        )

        Test.expect(txResult, Test.beSucceeded())
    }

    // Run another cycle to check that the Ballot option was set to the proper String value
    for account in accounts {
        scResult = executeScript(
            getBallotOptionSc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        newOption = scResult!.returnValue as! String

        Test.assert(newOption == voterOptions[account.address], 
            message: "Ballot for Election "
            .concat(selectedElectionId.toString())
            .concat(" does not have the desired option set: ")
            .concat(voterOptions[account.address]!)
            .concat(". Instead it has ")
            .concat(newOption)
        )
    }

    // Do another run with the second option set and ensure all went through
    for account in accounts {
        txResult = executeTransaction(
            castBallotTx,
            [selectedElectionId, moreVoterOptions[account.address]!],
            account
        )

        Test.expect(txResult, Test.beSucceeded())
    }

    for account in accounts {
        scResult = executeScript(
            getBallotOptionSc,
            [selectedElectionId, account.address]
        )

        Test.expect(scResult, Test.beSucceeded())

        newOption = scResult!.returnValue as! String

        Test.assert(newOption == moreVoterOptions[account.address],
            message: "Ballot for Election "
            .concat(selectedElectionId.toString())
            .concat(" does not have the desired option set: ")
            .concat(moreVoterOptions[account.address]!)
            .concat(". Instead it has ")
            .concat(newOption)
        )
    }
}

/**
    This test function submits the Ballots to the Elections set in their internal Election capabilities
**/
access(all) fun testSubmitBallot() {
    var txResult: Test.TransactionResult? = nil
    var scResult: Test.ScriptResult? = nil

    for account in accounts {
        txResult = executeTransaction(
            submitBallotTx,
            [selectedElectionId],
            account
        )

        Test.expect(txResult, Test.beSucceeded())
    }

    // Validate that all BallotSubmitted events match the expected number and parameters
}

/**
    This test finalises the base process by withdrawing the Ballots from the Election set in the selectedElectionId 
**/
access(all) fun _testWithdrawBallots() {

}

/**
    This test destroys the remaining process structures created during the voting process just to test that the account storage does gets cleaned and all the relevant events are emitted as expected.
**/
access(all) fun _testCleanEnvironment() {

}
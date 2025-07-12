import Test
import BlockchainHelpers
import "BallotStandard"
import "ElectionStandard"
import "BallotBurner"
import "VoteBooth"

access(all) let electionNames: [String] = [
    "01. Worlds best dog!",
    "02. Best cake in history!",
    "03. World human ever?"
]

access(all) let electionBallots: [String] = [
    "1 - Eddie; 2 - Argus; 3 - Both;",
    "1 - Tiramisu; 2 - Red Velvet; 3 - Brownies; 4 - Millionaire Shortbread;",
    "1 - Trump; 2 - Reagan; 3 - Bibi N.; 4 - Hitler; 5 - Cavaco Silva;"
]

access(all) let electionOptions: [[UInt8]] = [
    [1, 2, 3],
    [1, 2, 3, 4],
    [1, 2, 3, 4, 5]
]

access(all) let printLogs: Bool = true

access(all) let expectedBallotPrinterAdminStoragePath: StoragePath = /storage/BallotPrinterAdmin
access(all) let expectedBallotPrinterAdminPublicPath: PublicPath = /public/BallotPrinterAdmin
access(all) let expectedVoteBoxStoragePath: StoragePath = /storage/VoteBox
access(all) let expectedVoteBoxPublicPath: PublicPath = /public/VoteBox
access(all) let expectedBurnBoxStoragePath: StoragePath = /storage/BurnBox
access(all) let expectedBurnBoxPublicPath: PublicPath = /public/BurnBox

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000008)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let account04: Test.TestAccount = Test.createAccount()
access(all) let account05: Test.TestAccount = Test.createAccount()

access(all) let accounts: [Test.TestAccount] = [account01, account02, account03, account04, account05]

access(all) var ballots: {Address: UInt64} = {}

// TRANSACTIONS

// SCRIPTS

// EVENTS
// BallotStandard.cdc events
access(all) let ballotBurnedEventType: Type = Type<BallotStandard.BallotBurned>()

// ElectionStandard.cdc events
access(all) let ballotSubmittedEventType: Type = Type<ElectionStandard.BallotSubmitted>()
access(all) let ballotModifiedEventType: Type = Type<ElectionStandard.BallotModified>()
access(all) let ballotRevokedEventType: Type = Type<ElectionStandard.BallotRevoked>()
access(all) let ESNonNilResourceReturnedEventType: Type = Type<ElectionStandard.NonNilResourceReturned>()
access(all) let ballotWithdrawnEventType: Type = Type<ElectionStandard.BallotsWithdrawn>()
access(all) let electionDestroyedEventType: Type = Type<ElectionStandard.ElectionDestroyed>()

// BallotBurned.cdc events
access(all) let BBNonNilResourceReturnedEventType: Type = Type<BallotBurner.NonNilResourceReturned>()
access(all) let ballotSetToBurnEventType: Type = Type<BallotBurner.BallotSetToBurn>()
access(all) let burnBoxDestroyedEventType: Type = Type<BallotBurner.BurnBoxDestroyed>()

// VoteBooth.cdc events
access(all) let VBNonNilResourceReturnedEventType: Type = Type<VoteBooth.NonNilResourceReturned>()
access(all) let voteBoxCreatedEventType: Type = Type<VoteBooth.VoteBoxCreated>()
access(all) let voteBoxDestroyedEventType: Type = Type<VoteBooth.VoteBoxDestroyed>()
access(all) let electionCreatedEventType: Type = Type<VoteBooth.ElectionCreated>()
access(all) let ballotMintedEventType: Type = Type<VoteBooth.BallotMinted>()
access(all) let burnBoxCreatedEventType: Type = Type<VoteBooth.BurnBoxCreated>()

access(all) var eventNumberCount: {Type: Int} = {
    ballotBurnedEventType: 0,
    ballotSubmittedEventType: 0,
    ballotModifiedEventType: 0,
    ballotRevokedEventType: 0,
    ESNonNilResourceReturnedEventType: 0,
    ballotWithdrawnEventType: 0,
    electionDestroyedEventType: 0,
    BBNonNilResourceReturnedEventType: 0,
    ballotSetToBurnEventType: 0,
    burnBoxCreatedEventType: 0,
    burnBoxDestroyedEventType: 0,
    VBNonNilResourceReturnedEventType: 0,
    voteBoxCreatedEventType: 0,
    voteBoxDestroyedEventType: 0,
    electionCreatedEventType: 0,
    ballotMintedEventType: 0
}

access(all) var ballotMintedEvents: [AnyStruct] = []
access(all) var ballotBurnedEvents: [AnyStruct] = []
access(all) var ballotSubmittedEvents: [AnyStruct] = []
access(all) var ballotModifiedEvents: [AnyStruct] = []
access(all) var ballotRevokedEvents: [AnyStruct] = []
access(all) var ballotWithdrawnEvents: [AnyStruct] = []
access(all) var ballotSetToBurnEvents: [AnyStruct] = []
access(all) var electionCreatedEvents: [AnyStruct] = []
access(all) var electionDestroyedEvents: [AnyStruct] = []
access(all) var burnBoxCreatedEvents: [AnyStruct] = []
access(all) var burnBoxDestroyedEvents: [AnyStruct] = []
access(all) var voteBoxCreatedEvents: [AnyStruct] = []
access(all) var voteBoxDestroyedEvents: [AnyStruct] = []
access(all) var ESNonNilResourceReturnedEvents: [AnyStruct] = []
access(all) var BBNonNilResourceReturnedEvents: [AnyStruct] = []
access(all) var VBNonNilResourceReturnedEvents: [AnyStruct] = []

access(all) fun validateEvents() {
    ballotMintedEvents = Test.eventsOfType(ballotMintedEventType)
    ballotBurnedEvents = Test.eventsOfType(ballotBurnedEventType)
    ballotSubmittedEvents = Test.eventsOfType(ballotSubmittedEventType)
    ballotModifiedEvents = Test.eventsOfType(ballotModifiedEventType)
    ballotRevokedEvents = Test.eventsOfType(ballotRevokedEventType)
    ballotWithdrawnEvents = Test.eventsOfType(ballotWithdrawnEventType)
    ballotSetToBurnEvents = Test.eventsOfType(ballotSetToBurnEventType)
    electionCreatedEvents = Test.eventsOfType(electionCreatedEventType)
    electionDestroyedEvents = Test.eventsOfType(electionDestroyedEventType)
    burnBoxCreatedEvents = Test.eventsOfType(burnBoxCreatedEventType)
    burnBoxDestroyedEvents = Test.eventsOfType(burnBoxDestroyedEventType)
    voteBoxCreatedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    voteBoxDestroyedEvents = Test.eventsOfType(voteBoxDestroyedEventType)
    ESNonNilResourceReturnedEvents = Test.eventsOfType(ESNonNilResourceReturnedEventType)
    BBNonNilResourceReturnedEvents = Test.eventsOfType(BBNonNilResourceReturnedEventType)
    VBNonNilResourceReturnedEvents = Test.eventsOfType(VBNonNilResourceReturnedEventType)

    Test.assertEqual(ballotMintedEvents.length, eventNumberCount[ballotMintedEventType]!)
    Test.assertEqual(ballotBurnedEvents.length, eventNumberCount[ballotBurnedEventType]!)
    Test.assertEqual(ballotSubmittedEvents.length, eventNumberCount[ballotSubmittedEventType]!)
    Test.assertEqual(ballotModifiedEvents.length, eventNumberCount[ballotModifiedEventType]!)
    Test.assertEqual(ballotRevokedEvents.length, eventNumberCount[ballotRevokedEventType]!)
    Test.assertEqual(ballotWithdrawnEvents.length, eventNumberCount[ballotWithdrawnEventType]!)
    Test.assertEqual(ballotSetToBurnEvents.length, eventNumberCount[ballotSetToBurnEventType]!)
    Test.assertEqual(electionCreatedEvents.length, eventNumberCount[electionCreatedEventType]!)
    Test.assertEqual(electionDestroyedEvents.length, eventNumberCount[electionDestroyedEventType]!)
    Test.assertEqual(burnBoxCreatedEvents.length, eventNumberCount[burnBoxCreatedEventType]!)
    Test.assertEqual(burnBoxDestroyedEvents.length, eventNumberCount[burnBoxDestroyedEventType]!)
    Test.assertEqual(voteBoxCreatedEvents.length, eventNumberCount[voteBoxCreatedEventType]!)
    Test.assertEqual(voteBoxDestroyedEvents.length, eventNumberCount[voteBoxDestroyedEventType]!)
    Test.assertEqual(ESNonNilResourceReturnedEvents.length, eventNumberCount[ESNonNilResourceReturnedEventType]!)
    Test.assertEqual(BBNonNilResourceReturnedEvents.length, eventNumberCount[BBNonNilResourceReturnedEventType]!)
    Test.assertEqual(VBNonNilResourceReturnedEvents.length, eventNumberCount[VBNonNilResourceReturnedEventType]!)
}

access(all) fun setup() {
    // Start by deploying the dependencies of the VoteBooth contract
    var err: Test.Error? = Test.deployContract(
        name: "BallotStandard",
        path: "../contracts/BallotStandard.cdc",
        arguments: []
    )

    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "ElectionStandard",
        path: "../contracts/ElectionStandard.cdc",
        arguments: []
    )

    Test.expect(err, Test.beNil())

    err = Test.deployContract(
        name: "BallotBurner",
        path: "../contracts/BallotBurner.cdc",
        arguments: []
    )

    Test.expect(err, Test.beNil())

    // And finish with the VoteBooth contract itself.
    err = Test.deployContract(
        name: "VoteBooth",
        path: "../contracts/VoteBooth.cdc",
        arguments: [printLogs]
    )

    Test.expect(err, Test.beNil())

    if (printLogs) {
        // Print out the addresses of the test accounts
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

    // This setup phase should have emitted a BurnBoxCreated event. Test it
    eventNumberCount[burnBoxCreatedEventType] = eventNumberCount[burnBoxCreatedEventType]! + 1

    validateEvents()
}

// TODO: Plan the tests for this module
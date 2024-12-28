import Test
import "VoteBooth_std"
import BlockchainHelpers


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

access(all) let deployer: Test.TestAccount = Test.getAccount(0x000000000000000d)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()

// TRANSACTIONS

access(all) let testBallotPrinterTx: String = "../transactions/00_testBallotPrinterAdmin.cdc"

// SCRIPTS

// EVENTS
// Define the exact type of each expected event to be emitted with this contract
// NonFungibleToken events


// TODO: How the fuck do I create an account
// TODO: How do I create a NFT into a test account
// TODO: Continue from here


// This one is the setup where all the contracts (mains and dependencies) before anything else
access(all) fun setup() {
    // Deploy the dependencies before trying to deploy the main contract
    let err0: Test.Error? = Test.deployContract(
        name: "Burner",
        path: "../contracts/Burner.cdc",
        arguments: []
    )

    Test.expect(err0, Test.beNil())

    let err1: Test.Error? = Test.deployContract(
        name: "ViewResolver",
        path: "../contracts/ViewResolver.cdc",
        arguments: []
    )

    Test.expect(err1, Test.beNil())

    let err2: Test.Error? = Test.deployContract(
        name: "NonFungibleToken",
        path: "../contracts/NonFungibleToken.cdc",
        arguments: []
    )

    Test.expect(err2, Test.beNil())

    let err3: Test.Error? = Test.deployContract(
        name: "VoteBooth_std",
        path: "../contracts/VoteBooth_std.cdc",
        arguments: [electionName, electionSymbol, electionBallot, electionLocation, electionOptions]
    )

    Test.expect(err3, Test.beNil())
}

// Test the contract getters. These ones grab these properties directly from the contract so these should be OK since there are no resources being created and moved around... yet
// VoteBooth_std.getElectionName()
access(all) fun testGetElectionName() {
    Test.assertEqual(electionName, VoteBooth_std.getElectionName())
}
// VoteBooth_std.getElectionSymbol()
access(all) fun testGetElectionSymbol() {
    Test.assertEqual(electionSymbol, VoteBooth_std.getElectionSymbol())
}

// VoteBooth_std.getElectionLocation()
access(all) fun testGetElectionLocation() {
    Test.assertEqual(electionLocation, VoteBooth_std.getElectionLocation())
}

// VoteBooth_std.getElectionBallot()
access(all) fun testGetElectionBallot() {
    Test.assertEqual(electionBallot, VoteBooth_std.getElectionBallot())
}

// VoteBooth_std.getElectionOptions()
access(all) fun testGetElectionOptions() {
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
access(all) fun testDefaultPaths() {
    Test.assertEqual(VoteBooth_std.ballotPrinterAdminStoragePath, expectedBallotPrinterAdminStoragePath)

    Test.assertEqual(VoteBooth_std.ballotPrinterAdminPublicPath, expectedBallotPrinterAdminPublicPath)

    Test.assertEqual(VoteBooth_std.ballotCollectionStoragePath, expectedBallotCollectionStoragePath)

    Test.assertEqual(VoteBooth_std.ballotCollectionPublicPath, expectedBallotCollectionPublicPath)

    Test.assertEqual(VoteBooth_std.voteBoxPublicPath, expectedVoteBoxPublicPath)
    Test.assertEqual(VoteBooth_std.voteBoxStoragePath, expectedVoteBoxStoragePath)
}

access(all) fun testDefaultParameters() {
    Test.assertEqual(VoteBooth_std.totalBallotsMinted, 0 as UInt64)
    Test.assertEqual(VoteBooth_std.totalBallotsSubmitted, 0 as UInt64)

    // ballotOwners: {UInt64: Address}
    Test.assert(VoteBooth_std.getBallotOwners() == {})

    // owners: {Address: UInt64}
    Test.assert(VoteBooth_std.getOwners() == {})
}

access(all) fun testMinter() {
    // Run the corresponding transaction
    let txResult01: Test.TransactionResult = executeTransaction(
        testBallotPrinterTx,
        [],
        deployer
    )

    // This transaction should emit a bunch of events and, if all, goes well, should NOT emit a warning event. Yep, I'm using those
    Test.expect(txResult01, Test.beSucceeded())
}


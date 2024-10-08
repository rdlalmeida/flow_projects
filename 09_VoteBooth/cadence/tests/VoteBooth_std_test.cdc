import Test
import "VoteBooth_std"

access(all) let electionName: String = "World's best dog ever!"
access(all) let electionSymbol: String = "WBDE"
access(all) let electionLocation: String = "Campinho"
access(all) let electionBallot: String = "Who was the best dog this summer? Options: \n1 - Eddie, \n2 - Argus, \n3 - Both, \n4 - None"
access(all) let electionOptions: [UInt64] = [1, 2, 3, 4]

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
access(all) fun testGetElectionName() {
    Test.assertEqual(electionName, VoteBooth_std.getElectionName())
}

access(all) fun testGetElectionSymbol() {
    Test.assertEqual(electionSymbol, VoteBooth_std.getElectionSymbol())
}

access(all) fun testGetElectionLocation() {
    Test.assertEqual(electionLocation, VoteBooth_std.getElectionLocation())
}

access(all) fun testGetElectionBallot() {
    Test.assertEqual(electionBallot, VoteBooth_std.getElectionBallot())
}

access(all) fun testGetElectionOptions() {
    Test.assertEqual(electionOptions, VoteBooth_std.getElectionOptions())
}

access(all) 

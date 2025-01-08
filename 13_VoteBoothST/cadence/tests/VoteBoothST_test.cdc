import Test
import BlockchainHelpers
import "VoteBoothST"
import "NonFungibleToken"

access(all) let electionName: String = "World's best dog ever!"
access(all) let electionSymbol: String = "WBDE"
access(all) let electionLocation: String = "Campinho"
access(all) let electionBallot: String = "Who was the best dog this summer? Options: \n1 - Eddie, \n2 - Argus, \n3 - Both, \n4 - None"
access(all) let electionOptions: String = "1;2;3;4"

access(all) let expectedBallotPrinterAdminStoragePath: StoragePath = /storage/BallotPrinterAdmin
access(all) let expectedBallotPrinterAdminPublicPath: PublicPath = /public/BallotPrinterAdmin
access(all) let expectedBallotCollectionStoragePath: StoragePath = /storage/BallotCollection
access(all) let expectedBallotCollectionPublicPath: PublicPath = /public/BallotCollection
access(all) let expectedVoteBoxStoragePath: StoragePath = /storage/VoteBox
access(all) let expectedVoteBoxPublicPath: PublicPath = /public/VoteBox

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000008)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let accounts: [Test.TestAccount] = [account01, account02, account03]
access(all) let ballots: {String: {String: String}} = {}

// TRANSACTIONS
access(all) let testBallotPrinterTx: String = "../transactions/01_test_ballot_printer_admin.cdc"
access(all) let testBallotPrinterAdminTx: String = "../transactions/02_test_ballot_printer_admin_reference.cdc"
access(all) let voteBoxCreationTx: String = "../transactions/03_create_vote_box.cdc"
access(all) let mintBallotToAccountTx: String = "../transactions/04_mint_ballot_to_account.cdc"

// SCRIPTS
access(all) let testVoteBoxSc: String = "../scripts/01_test_vote_box.cdc"
access(all) let getVoteOptionsSc: String = "../scripts/02_get_vote_option.cdc"
access(all) let getIDsSc: String = "../scripts/03_get_IDs.cdc"

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

access(all) fun setup() {
    let err: Test.Error? = Test.deployContract(
        name: "VoteBoothST",
        path: "../contracts/VoteBoothST.cdc",
        arguments: [electionName, electionSymbol, electionBallot, electionLocation, electionOptions]
    )

    Test.expect(err, Test.beNil())
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
    let options: [UInt64] = VoteBoothST.getElectionOptions()

    var parsedElectionOptions: [UInt64] = []
    var optionElements: [String] = electionOptions.split(separator: ";")
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
    Test.assertEqual(VoteBoothST.ballotPrinterAdminStoragePath, expectedBallotPrinterAdminStoragePath)

    Test.assertEqual(VoteBoothST.ballotPrinterAdminPublicPath, expectedBallotPrinterAdminPublicPath)

    Test.assertEqual(VoteBoothST.ballotCollectionStoragePath, expectedBallotCollectionStoragePath)

    Test.assertEqual(VoteBoothST.ballotCollectionPublicPath, expectedBallotCollectionPublicPath)

    Test.assertEqual(VoteBoothST.voteBoxPublicPath, expectedVoteBoxPublicPath)

    Test.assertEqual(VoteBoothST.voteBoxStoragePath, expectedVoteBoxStoragePath)
}

access(all) fun testDefaultParameters() {
    Test.assertEqual(VoteBoothST.totalBallotsMinted, 0 as UInt64)
    Test.assertEqual(VoteBoothST.totalBallotsSubmitted, 0 as UInt64)

    Test.assert(VoteBoothST.getBallotOwners() == {})

    Test.assert(VoteBoothST.getOwners() == {})
}


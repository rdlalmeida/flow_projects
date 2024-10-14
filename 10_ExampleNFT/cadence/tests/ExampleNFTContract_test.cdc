import Test
import "NonFungibleToken"
import "ExampleNFTContract"
import BlockchainHelpers

/* 
    VERY IMPORTANT NOTE: Apparently, in order for a test function to execute automatically, the function name needs to start with 'test<SomeOtherNames>'. If not, the testing module ignores the function! Weird behaviour, but I need to take this into account.

    TODO: I'm stuck with the authorization crap... How the fuck do I get the neccessary entitlements in a TestAccount??? I need to be able to load and save stuff into storage but I cannot do it with any of the info published so far...

*/

access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()

// Get the account that it is configured in the "testing" field for the main contract to test
access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000007)

// Paths to transaction files
access(all) let createCollectionTx: String = "../transactions/01_setup_example_collection.cdc"
access(all) let mintExampleNFTTx: String = "../transactions/02_mint_example_nft.cdc"
access(all) let transferExampleNFTTx: String = "../transaction/03_transfer_example_nft.cdc"

// Paths to script files
access(all) let getNFTCollectionScp: String = "../scripts/01_get_example_nfts_ids.cdc"

access(all) fun setup() {
    log("About to test these Tests...")

    let err: Test.Error? = Test.deployContract(
        name: "ExampleNFTContract",
        path: "../contracts/ExampleNFTContract.cdc",
        arguments: []
    )

    Test.expect(err, Test.beNil())
}

// Test the creation of an empty collection
access(all) fun testCreateCollection() {
    // Run the Collection creation transaction with account01 and account 02 to create collections in both account storage
    let txResult01: Test.TransactionResult = executeTransaction(
        createCollectionTx,
        [],
        account01
    )

    Test.expect(txResult01, Test.beSucceeded())

    // Log the transaction result just to see what I'm working with here
    // log("Transaction 01: ")
    // log(txResult01)

    let txResult02: Test.TransactionResult = executeTransaction(
        createCollectionTx,
        [],
        account02
    )

    Test.expect(txResult02, Test.beSucceeded())

    // log("Transaction 02: ")
    // log(txResult02)
}

// Test that each Collection created is still empty
access(all) fun testEmptyCollections() {
    // Run the script that retrieves the items in the collection and verify that both Collections are empty of NFTs
    let scriptResult01: Test.ScriptResult = executeScript(
        getNFTCollectionScp,
        [account01.address]
    )

    // Extract the script results
    let collection01: [UInt64] = (scriptResult01.returnValue as! [UInt64]?)!

    Test.assertEqual(0, collection01.length)

    log("ScriptResult01: ")
    log(scriptResult01)

    log("Collection01: ")
    log(collection01)

    // Repeat the process to the other collection
    let scriptResult02: Test.ScriptResult = executeScript(
        getNFTCollectionScp,
        [account02.address]
    )

    let collection02: [UInt64] = (scriptResult02.returnValue as! [UInt64]?)!

    Test.assertEqual(0, collection02.length)
}

/*
    TODO: Test that minting a NFT with the signer works, but with any of the other accounts doesn't
    TODO: Test that non-NFT owners cannot do anything with them
    TODO: Test that the Minter can only be used by the contract deployer
    TODO: Test that the deployer cannot do anything with the NFTs after these are minted
*/

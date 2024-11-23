import Test
import "ExampleNFTContract"
import "NonFungibleToken"
import BlockchainHelpers
import "FlowFees"

// Get the main deployer account, which is defined in the 'testing' field from the contract specification in this project's flow.json

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000007);

// Create another two accounts needed to do mints and transfers
access(all) let account01: Test.TestAccount = Test.createAccount();
access(all) let account02: Test.TestAccount = Test.createAccount();

// Define the transactions to execute later
access(all) let createCollectionTx: String = "../transactions/01_setup_example_collection.cdc";
access(all) let mintExampleNFTTx : String = "../transactions/02_mint_example_nft.cdc";
access(all) let transferExampleNFTTx: String = "../transactions/03_transfer_example_nft.cdc";
access(all) let testNFTFunctionTx: String = "--/transactions/04_test_nft_functions.cdc";

// The same for scripts
access(all) let getNFTCollectionSc: String = "../scripts/01_get_example_nfts_ids.cdc";
access(all) let borrowNFTSc: String = "../scripts/02_borrow_nft.cdc";

// Set the events types to be able to capture them later
access(all) let mintEventType: Type = Type<ExampleNFTContract.NFTMinted>()
access(all) let emptyCollectionCreatedEventType: Type = Type<ExampleNFTContract.EmptyCollectionCreated>();
access(all) let depositEventType: Type = Type<NonFungibleToken.Deposited>()
access(all) let withdrawEventType: Type = Type<NonFungibleToken.Withdrawn>()

// Event types for the FlowFees events
access(all) let feesDeductedEventType: Type = Type<FlowFees.FeesDeducted>()
access(all) let tokensDepositedEventType: Type = Type<FlowFees.TokensDeposited>()
access(all) let tokensWithdrawnEventType: Type = Type<FlowFees.TokensWithdrawn>()

// Setup function to deploy the main contract and any other initial configurations
access(all) fun setup() {
    // Begin by retrieving and printing the current fee parameters
    let beforeFeeParameters: FlowFees.FeeParameters = FlowFees.getFeeParameters();

    log("Fee parameters before contract deploy: ");
    log(beforeFeeParameters);

    let err: Test.Error? = Test.deployContract(
        name: "ExampleNFTContract",
        path: "../contracts/ExampleNFTContract.cdc",
        arguments: []
    )

    // Capture and analyse any FeeDeducted Events emitted
    let feesDeductedEvents: [AnyStruct] = Test.eventsOfType(feesDeductedEventType);
    log("Captured ".concat(feesDeductedEvents.length.toString()).concat(" events!"));

    // Cast and printout every event captured from the type considered.
    var index: Int = 0;
    for feeEvent in feesDeductedEvents {
        let newFeeEvent: FlowFees.FeesDeducted = feeEvent as! FlowFees.FeesDeducted

        log("FlowFee Event #".concat(index.toString()).concat(":"));
        log(newFeeEvent);
    }


    // Check if the parameters have changed after deploying the main contract
    let afterFeeParameters: FlowFees.FeeParameters = FlowFees.getFeeParameters();

    log("Fee parameters after contract deploy: ");
    log(afterFeeParameters);

    Test.expect(err, Test.beNil())
}
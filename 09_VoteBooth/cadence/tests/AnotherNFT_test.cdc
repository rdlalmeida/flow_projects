import Test

access(all) let account = Test.createAccount()

access(all) fun testContract() {
    let err = Test.deployContract(
        name: "AnotherNFT",
        path: "../contracts/AnotherNFT.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())
}
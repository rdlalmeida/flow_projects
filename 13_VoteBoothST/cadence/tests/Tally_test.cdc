import Test

access(all) let account = Test.createAccount()

access(all) fun testContract() {
    let err = Test.deployContract(
        name: "Tally",
        path: "../contracts/Tally.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())
}
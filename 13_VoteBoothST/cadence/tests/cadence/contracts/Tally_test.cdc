import Test

access(all) let account = Test.createAccount()

access(all) fun testContract() {
    let err = Test.deployContract(
        name: "cadence/contracts/Tally",
        path: "../contracts/cadence/contracts/Tally.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())
}
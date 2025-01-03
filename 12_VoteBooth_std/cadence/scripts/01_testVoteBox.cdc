import "VoteBooth_std"

access(all) fun main(accountToTest: Address): Bool {
    let testAccount: &Account = getAccount(accountToTest)

    return testAccount.capabilities.exists(VoteBooth_std.voteBoxPublicPath)
}
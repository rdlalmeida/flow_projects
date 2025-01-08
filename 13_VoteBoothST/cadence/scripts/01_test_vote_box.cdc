import "VoteBoothST"

access(all) fun main(accountToTest: Address): Bool {
    let testAccount: &Account = getAccount(accountToTest)

    return testAccount.capabilities.exists(VoteBoothST.voteBoxPublicPath)
}
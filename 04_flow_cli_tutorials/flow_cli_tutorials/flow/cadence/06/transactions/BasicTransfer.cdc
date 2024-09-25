import BasicToken from "../contracts/BasicToken.cdc"

// This transaction is used to withdraw and deposit tokens with a Vault
transaction(amount: UFix64) {
    prepare(account: AuthAccount) {
        /*
            Withdraw tokens from your vault by borrowing a reference to it and calling the withdraw function with that reference
        */
        let vaultRef = account.borrow<&BasicToken.Vault>(from: BasicToken.vaultStorage)
            ?? panic("Could not borrow a reference to the owner's vault")

        let temporaryVault <- vaultRef.withdraw(amount: amount)

        let currentBalance = vaultRef.balance

        // Deposit your tokens back to the Vault
        // vaultRef.deposit(from: <- temporaryVault)

        // Destroy the temporary value with all the withdrawned tokens in it. This is akin to a token burn (probably that's how they do it too..)
        destroy temporaryVault

        log("Withdrawed ".concat(amount.toString()).concat(" tokens successfully!"))
        log("Vault's balance is now ".concat(currentBalance.toString()).concat(" tokens"))
    }
}
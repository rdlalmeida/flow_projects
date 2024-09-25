import ExampleToken from "../contracts/ExampleToken.cdc"

/*
    This transactions is a template for a transaction that could be used by anyone to send tokens to another account that owns a Vault
*/
transaction(withdrawAmount: UFix64, recipientAddress: Address) {
    /*
        Temporary Vault object that holds the balance that is being transferred
    */
    var temporaryVault: @ExampleToken.Vault

    prepare(account: AuthAccount) {
        /*
            Withdraw tokens from your vault by borrowing a reference to it and calling the withdraw function with that reference
        */
        let vaultRef = account.borrow<&ExampleToken.Vault>(from: ExampleToken.VaultStoragePath)
            ?? panic("Could not borrow a reference to the owner's vault")

        self.temporaryVault <- vaultRef.withdraw(amount: withdrawAmount)
    }

    execute{
        // Get the recipient's public account object
        let recipient = getAccount(recipientAddress)

        /*
            Get the recipient's Receiver reference to their Vault by borrowing the reference from the public capability
        */
        let receiverRef = recipient.getCapability(ExampleToken.VaultPublicPath).borrow<&ExampleToken.Vault{ExampleToken.Receiver}>()
            ?? panic("Could not borrow a reference to the receiver")

        // Deposit your tokens to their Vault
        receiverRef.deposit(from: <- self.temporaryVault)

        log("Transfer succeded!")
    }
}
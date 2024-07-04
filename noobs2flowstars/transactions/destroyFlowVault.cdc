import FlowToken from "../../float/src/cadence/core-contracts/FlowToken.cdc"
import FungibleToken from "../../float/src/cadence/core-contracts/FungibleToken.cdc"

transaction(burnerAccount: Address) {
    let burnerRef: &FlowToken.Burner
    let vaultToDestroy: @FlowToken.Vault
    prepare(signer: AuthAccount) {
        // Fill out the internal parameters
        self.burnerRef = getAccount(burnerAccount).getCapability<&FlowToken.Burner>(FlowToken.burnerPublic).borrow() ??
            panic("Unable to get a FlowToken.Burner reference for account ".concat(burnerAccount.toString()))

        // Retrieve the vault from the signer account
        self.vaultToDestroy <- signer.load<@FlowToken.Vault>(from: /storage/flowVault) ??
            panic("Unable to retrieve the FlowToken.Vault to destroy for account ".concat(signer.address.toString()))
    }

    execute {
        // Withdraw all the remaining tokens from the Vault to destroy into a @FungibleToken.Vault that can be destroyed with the burner thin
        let tokensToBurn: @FungibleToken.Vault <- self.vaultToDestroy.withdraw(amount: self.vaultToDestroy.balance)

        log(tokensToBurn.balance.toString().concat(" Flow tokens withdraw"))
        log("Current Vault balance: ".concat(self.vaultToDestroy.balance.toString()))

        // Burn the tokens using the burner
        self.burnerRef.burnTokens(from: <- tokensToBurn)

        log("Tokens burned successfully")

        // The vault is now empty. Destroy it
        destroy self.vaultToDestroy

        log("Vault destroyed!")

    }
}
 
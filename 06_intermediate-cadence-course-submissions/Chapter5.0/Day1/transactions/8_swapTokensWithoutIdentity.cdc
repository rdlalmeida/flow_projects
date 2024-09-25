/*
    Transaction to swap token without using the Identity Resource
*/
import Swap from "../contracts/Swap.cdc"
import FlowToken from "../contracts/FlowToken.cdc"

// import Swap from 0xb7fb1e0ae6485cf6
// import FlowToken from 0xb7fb1e0ae6485cf6

transaction(amount: UFix64) {
    let flowVaultRef: &FlowToken.Vault
    let vaultToExchange: @FlowToken.Vault
    prepare(signer: AuthAccount) {
        // This one is simpler. Get the reference to the vault in storage
        self.flowVaultRef = signer.borrow<&FlowToken.Vault>(from: FlowToken.vaultStorage) ??
            panic("Unable to retrieve a valid FlowToken.Vault reference for user ".concat(signer.address.toString()))

        // And use it to generate the Vault to use for the exchange 
        self.vaultToExchange <- self.flowVaultRef.withdraw(amount: amount) as! @FlowToken.Vault
    }

    execute {
        // Run the contract function without needed the Identity Resource
        Swap.swap(incomingVault: <- self.vaultToExchange, vaultRef: self.flowVaultRef)
    }
}
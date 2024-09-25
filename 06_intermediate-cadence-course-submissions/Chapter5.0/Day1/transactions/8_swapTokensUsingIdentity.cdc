// import Swap from "../contracts/Swap.cdc"
// import FlowToken from "../contracts/FlowToken.cdc"

import Swap from 0xb7fb1e0ae6485cf6
import FlowToken from 0xb7fb1e0ae6485cf6

transaction(flowAmountSwap: UFix64) {
    
    let flowVaultRef: &FlowToken.Vault
    let swapperIdentityRef: &Swap.SwapperIdentity
    prepare(signer: AuthAccount) {
        // Deal with the local references
        self.flowVaultRef = signer.borrow<&FlowToken.Vault>(from: FlowToken.vaultStorage) ??
            panic("Unable to retrieve a reference to a FlowToken.Vaul from account ".concat(signer.address.toString()))

        self.swapperIdentityRef = signer.getCapability<&Swap.SwapperIdentity>(Swap.swapperPublic).borrow() ??
            panic("Unable to retrieve a reference to a SwapperIdentity from account ".concat(signer.address.toString()))
    }

    execute {
        // Withdraw the amount of tokens to swap from the signer's Vault reference
        let vaultToSwap: @FlowToken.Vault <- self.flowVaultRef.withdraw(amount: flowAmountSwap) as! @FlowToken.Vault

        // Ready to execute the swapping function
        self.swapperIdentityRef.swap(flowVault: <- vaultToSwap)
    }
}
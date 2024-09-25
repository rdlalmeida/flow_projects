/*
    This transaction ensures that a user account gets ready for a Swap, namely by setting the RicardoCoin.Vault and SwapIdentity properly
*/
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"
import Swap from "../contracts/Swap.cdc"

// Testnet deployments
// import FungibleToken from 0x9a0766d93b6608b7
// import FlowToken from 0xb7fb1e0ae6485cf6
// import RicardoCoin from 0xb7fb1e0ae6485cf6
// import Swap from 0xb7fb1e0ae6485cf6

transaction() {
    prepare(signer: AuthAccount) {
        // This transaction does a lot of borrows, loads and saves from the signer account so all of it is going to happen in the prepare phase
        // FlowToken stuff
        if let flowVaultRef: &FlowToken.Vault = signer.borrow<&FlowToken.Vault>(from: FlowToken.vaultStorage) {
            // Nothing to do here.
            log ("Found a vault of type ".concat(flowVaultRef.getType().identifier))
        }
        else {
            // There's no FlowToken.Vault configured yet. Create and save a new one
            let flowVault: @FungibleToken.Vault <- FlowToken.createEmptyVault()
            log ("Vault of type ".concat(flowVault.getType().identifier).concat(" created!"))

            signer.save(<- flowVault, to: FlowToken.vaultStorage)
        }

        // There's a valid Vault in storage now. Test the capabilities and re-link them if needed
        if !(signer.getCapability<&FlowToken.Vault{FungibleToken.Balance}>(FlowToken.vaultBalancePublic).check()) {
            // If the Capability to the Balance interface is not valid, re-create it
            signer.unlink(FlowToken.vaultBalancePublic)
            signer.link<&FlowToken.Vault{FungibleToken.Balance}>(FlowToken.vaultBalancePublic, target: FlowToken.vaultStorage)
        }
        
        let balanceCap: Capability<&FlowToken.Vault{FungibleToken.Balance}> = signer.getCapability<&FlowToken.Vault{FungibleToken.Balance}>(FlowToken.vaultBalancePublic)

        log("FlowToken.Vault balance capability has type ".concat(balanceCap.getType().identifier))

        if let balanceRef: &FlowToken.Vault{FungibleToken.Balance} = balanceCap.borrow() {
            log("Borrowed a ".concat(balanceRef.getType().identifier).concat(". It has balance = ").concat(balanceRef.balance.toString()))
        }
        else {
            log("Unable to borrow a Balance ref!")
        }

        if !(signer.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(FlowToken.vaultReceiverPublic).check()) {
            signer.unlink(FlowToken.vaultBalancePublic)
            signer.link<&FlowToken.Vault{FungibleToken.Receiver}>(FlowToken.vaultReceiverPublic, target: FlowToken.vaultStorage)
        }

        // Repeat the process to the RicardoCoin Vault
        if let ricardoVaultRef: &RicardoCoin.Vault = signer.borrow<&RicardoCoin.Vault>(from: RicardoCoin.vaultStorage) {
            // Nothing to do
        }
        else {
            let ricardoVault: @FungibleToken.Vault <- RicardoCoin.createEmptyVault()
            signer.save(<- ricardoVault, to: RicardoCoin.vaultStorage)
        }

        // There's a proper Vault in storage at this point. Carry on
        if !(signer.getCapability<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic).check()) {
            signer.unlink(RicardoCoin.vaultBalancePublic)
            signer.link<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic, target: RicardoCoin.vaultStorage)
        }

        if !(signer.getCapability<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic).check()) {
            signer.unlink(RicardoCoin.vaultReceiverPublic)
            signer.link<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic, target: RicardoCoin.vaultStorage)
        }

        // Once again with the SwapIdentity resource
        if let swapIdentityRef: &Swap.SwapperIdentity = signer.borrow<&Swap.SwapperIdentity>(from: Swap.swapperStorage) {
            // There's a Swapper already in storage. Nothing to do
        }
        else {
            let swapperIdentity: @Swap.SwapperIdentity <- Swap.createSwapperIdentity()
            signer.save(<- swapperIdentity, to: Swap.swapperStorage)
        }

        if !(signer.getCapability<&Swap.SwapperIdentity>(Swap.swapperPublic).check()) {
            signer.unlink(Swap.swapperPublic)
            signer.link<&Swap.SwapperIdentity>(Swap.swapperPublic, target: Swap.swapperStorage)
        }
    }

    execute {

    }
}
 
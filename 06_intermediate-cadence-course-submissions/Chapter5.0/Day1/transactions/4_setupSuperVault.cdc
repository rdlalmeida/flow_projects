/*
    This transaction sets a Vault under the new RicardoCoinSuperAdmin contract that allows an Administrator resource to withdraw RicardoCoin tokens and replace
    those with $FLOW tokens. In this case I need to setup the RicardoCoin Vault, as well as the FLOW Vault to hold the other tokens
*/

import FlowToken from "../contracts/FlowToken.cdc"
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoinSuperAdmin from "../contracts/RicardoCoinSuperAdmin.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // This is just a matter of creating, saving and linking the Resources
        let ricardoVault: @FungibleToken.Vault <- RicardoCoinSuperAdmin.createEmptyVault()
        signer.save(<- ricardoVault, to: RicardoCoinSuperAdmin.vaultStorage)

        // This one needs to be linked to three interfaces
        signer.link<&RicardoCoinSuperAdmin.Vault{FungibleToken.Balance}>(RicardoCoinSuperAdmin.vaultBalancePublic, target: RicardoCoinSuperAdmin.vaultStorage)
        signer.link<&RicardoCoinSuperAdmin.Vault{FungibleToken.Receiver}>(RicardoCoinSuperAdmin.vaultReceiverPublic, target: RicardoCoinSuperAdmin.vaultStorage)
        signer.link<&RicardoCoinSuperAdmin.Vault{RicardoCoinSuperAdmin.AdminVaultAccess}>(RicardoCoinSuperAdmin.adminAccessVaultPublic, target: RicardoCoinSuperAdmin.vaultStorage)

        log("RicardoCoinSuperAdmin.Vault set for account ".concat(signer.address.toString()))

        // Now for the FlowToken vault
        let flowVault: @FungibleToken.Vault <- FlowToken.createEmptyVault()
        signer.save(<- flowVault, to: FlowToken.vaultStorage)

        signer.link<&FlowToken.Vault{FungibleToken.Receiver}>(FlowToken.vaultReceiverPublic, target: FlowToken.vaultStorage)
        signer.link<&FlowToken.Vault{FungibleToken.Balance}>(FlowToken.vaultBalancePublic, target: FlowToken.vaultStorage)

        log("FlowToken.Vault set for account ".concat(signer.address.toString()))
    }

    execute {

    }
}
/*
    Transaction to reset the storage accounts for the transaction signers regarding the RicardoCoinSuperAdmin contract
*/

import RicardoCoinSuperAdmin from "../contracts/RicardoCoinSuperAdmin.cdc"
import FlowToken from "../contracts/FlowToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        if let ricardoVaultReference: &RicardoCoinSuperAdmin.Vault = signer.borrow<&RicardoCoinSuperAdmin.Vault>(from: RicardoCoinSuperAdmin.vaultStorage) {
            let randomRicardoVault: @AnyResource <- signer.load<@AnyResource>(from: RicardoCoinSuperAdmin.vaultStorage)
            destroy randomRicardoVault

            signer.unlink(RicardoCoinSuperAdmin.vaultBalancePublic)
            signer.unlink(RicardoCoinSuperAdmin.vaultReceiverPublic)
            signer.unlink(RicardoCoinSuperAdmin.adminAccessVaultPublic)

            log("Removed a RicardoCoinSuperAdmin.Vault from account ".concat(signer.address.toString()))
        }
        
        
        if let flowVaultReference: &FlowToken.Vault = signer.borrow<&FlowToken.Vault>(from: FlowToken.vaultStorage) {
            let randomFlowVault: @AnyResource <- signer.load<@AnyResource>(from: FlowToken.vaultStorage)
            destroy randomFlowVault

            signer.unlink(FlowToken.vaultBalancePublic)
            signer.unlink(FlowToken.vaultReceiverPublic)

            log("Removed a FlowToken.Vault from account ".concat(signer.address.toString()))
        }

    }

    execute {

    }
}
 
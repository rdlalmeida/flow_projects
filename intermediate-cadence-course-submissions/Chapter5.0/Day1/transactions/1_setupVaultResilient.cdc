import RicardoCoin from "../contracts/RicardoCoin.cdc"
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Test if there's a Vault already in storage before attempting to create a new one. Begin by borrowing a reference from storage and test if its nill
        let vaultReference: &RicardoCoin.Vault? = signer.borrow<&RicardoCoin.Vault>(from: RicardoCoin.vaultStorage)

        if (vaultReference != nil) {
            // If a proper Reference was found, test the Capability next
            let vaultCapability: Capability<&RicardoCoin.Vault{FungibleToken.Receiver}> 
                = signer.getCapability<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic)

            if (!vaultCapability.check()) {
                // The link to the Public Storage is not OK. Redo it given that the Vault is properly stored in main storage
                // Start by unlinking whatever may be at that Public path
                signer.unlink(RicardoCoin.vaultReceiverPublic)
                signer.unlink(RicardoCoin.vaultBalancePublic)

                // Re-link the capability
                signer.link<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic, target: RicardoCoin.vaultStorage)
                signer.link<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic, target: RicardoCoin.vaultStorage)

                log("Re-linked Capabilities for account ".concat(signer.address.toString()))
            }
            else {
                log("Account ".concat(signer.address.toString()).concat(" has a proper RicardoCoin.Vault save and publicly linked"))
            }
        }
        else {
            // In this case the storage path does not have what we need.
            // NOTE: Something else may be there (in the storage path), so "clean" it up just in case
            let randomVault: @AnyResource <- signer.load<@AnyResource>(from: RicardoCoin.vaultStorage)
            destroy randomVault

            // Unlink any Capabilities in the Public storage as well
            signer.unlink(RicardoCoin.vaultReceiverPublic)
            signer.unlink(RicardoCoin.vaultBalancePublic)

            // Create, save and link a new Vault to this user's storage
            let newVault: @FungibleToken.Vault <- RicardoCoin.createEmptyVault()
            signer.save(<- newVault, to: RicardoCoin.vaultStorage)

            signer.link<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic, target: RicardoCoin.vaultStorage)
            signer.link<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic, target: RicardoCoin.vaultStorage)

            log("New RicardoCoin.Vault created and linked for account ".concat(signer.address.toString()))
        }
    }

    execute {

    }
}
 
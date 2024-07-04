import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Create the new vault
        let newVault: @FungibleToken.Vault <- RicardoCoin.createEmptyVault()

        // Save it to storage and link the Provider and Balance to the Public Storage
        signer.save(<- newVault, to: RicardoCoin.adminStorage)

        signer.link<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic, target: RicardoCoin.vaultStorage)
        signer.link<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic, target: RicardoCoin.vaultBalancePublic)
    }

    execute {

    }
}
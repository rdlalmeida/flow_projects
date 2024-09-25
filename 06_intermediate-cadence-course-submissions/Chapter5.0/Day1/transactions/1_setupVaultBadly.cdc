/*
    This transaction sets up a RicardoCoin.Vault wrongly on purpose, in order to test the script that recreates the link
*/
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // CASE 1 - Link not done correctly
        // // Create the Vault and save it to storage
        // let newVault: @FungibleToken.Vault <- RicardoCoin.createEmptyVault()

        // signer.save(<- newVault, to: RicardoCoin.vaultStorage)

        // // Botch up the linking of the Balance part by "forgetting" the interface
        // signer.link<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultBalancePublic, target: RicardoCoin.vaultStorage)

        // CASE 2 - Differente Resource Type saved to the Storage Path
        // Create a FlowToken Vault insted in this case but save and link it as if it was a RicardoCoin one
        let newVault: @FungibleToken.Vault <- FlowToken.createEmptyVault()

        signer.save(<- newVault, to: RicardoCoin.vaultStorage)

        signer.link<&FlowToken.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic, target: RicardoCoin.vaultStorage)
    }

    execute {

    }
}
 
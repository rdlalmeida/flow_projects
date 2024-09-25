/*
    Use this transaction to destroy a user's Vault. Necessary for when there are significant changes to the contracts
    governing these resources
*/
import RicardoCoin from "../contracts/RicardoCoin.cdc"
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Load and unlink any Vault resources in the user's account. Its for destruction purposes, so don't bother with getting the types correct
        let randomVault: @AnyResource <- signer.load<@AnyResource>(from: RicardoCoin.vaultStorage)
        destroy (randomVault)

        signer.unlink(RicardoCoin.vaultReceiverPublic)
        signer.unlink(RicardoCoin.vaultBalancePublic)

        // Done
        log("Account ".concat(signer.address.toString()).concat(" was cleaned up from any Vault References"))
    }

    execute {

    }
}
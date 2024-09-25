import FlowToken from "../../float/src/cadence/core-contracts/FlowToken.cdc"
import FungibleToken from "../../float/src/cadence/core-contracts/FungibleToken.cdc"
import Shapes from "../contracts/Shapes.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let vaultRef: &FlowToken.Vault? = signer.borrow<&FlowToken.Vault>(from: /storage/flowVault)

        if (vaultRef == nil) {
            let flowVault: @FlowToken.Vault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
            signer.save(<- flowVault, to: /storage/flowVault)

            signer.link<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowVault, target: /storage/flowVault)

            log("Vault created for account ".concat(signer.address.toString()))
        }
        else {
            log("Account ".concat(signer.address.toString()).concat(" already has a Vault in storage"))
            // let randomVault: @AnyResource <- signer.load<@AnyResource>(from: /storage/flowVault)
            // destroy randomVault

            // signer.unlink(/public/flowVault)
        }
    }

    execute {

    }
}

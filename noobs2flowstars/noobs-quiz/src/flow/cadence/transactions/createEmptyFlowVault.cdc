import FlowToken from 0xFLOAT
import FungibleToken from 0xFungibleToken

transaction() {
    prepare(signer: AuthAccount) {
        
        // We were able to determine this path doing an iteration using the AuthAccount.forEachPublic on a testnet account with a Flow Vault configured
        let vaultPublicPath: PublicPath = /public/flowTokenReceiver

        let flowVaultCap: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
            = getAccount(accountToCheck).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(vaultPublicPath)

        // Proceed with the creation of a new Vault only if none was found in storage
        if (flowVaultCap.check()) {
            let flowVault: @FlowToken.Vault <- FlowToken.createEmptyVault() as! @FlowToken.Vault
            signer.save(<- flowVault, to: /storage/flowVault)

            signer.link<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowVault, target: /storage/flowVault)
        }
    }

    execute {

    }
}

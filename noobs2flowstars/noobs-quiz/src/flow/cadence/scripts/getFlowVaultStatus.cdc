import FlowToken from 0xFlowToken
import FungibleToken from 0xFungibleToken

pub fun main(accountToCheck: Address): Bool {

    // We were able to determine this path doing an iteration using the AuthAccount.forEachPublic on a testnet account with a Flow Vault configured
    let vaultPublicPath: PublicPath = /public/flowTokenReceiver

    let flowVaultCap: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
        = getAccount(accountToCheck).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(vaultPublicPath)

    return flowVaultCap.check()
}

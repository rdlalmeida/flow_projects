import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"

pub fun main(user: Address): Bool {
    let userAccount: PublicAccount = getAccount(user)
    // Grab Capabilities for both interfaces that are expected to be linked publicly for all Vaults and move fro there
    let vaultReceiverCapability: Capability<&RicardoCoin.Vault{FungibleToken.Receiver}>
        = userAccount.getCapability<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic)

    let vaultBalanceCapability: Capability<&RicardoCoin.Vault{FungibleToken.Balance}>
        = userAccount.getCapability<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic)

    // The return can be composed with the check functions applied to both Capabilities
    return (vaultReceiverCapability.check() && vaultBalanceCapability.check())
}
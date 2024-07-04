import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"

pub fun main(user: Address): UFix64 {
    // Get a reference to the Balance part of the user's RicardoCoin Vault
    let balanceReference: &RicardoCoin.Vault{FungibleToken.Balance}
        = getAccount(user).getCapability<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic).borrow() ??
            panic("Account ".concat(user.toString()).concat(" does not have a proper RicardoCoin.Vault{FungibleToken.Balance} set up!"))
    
    return balanceReference.balance
}
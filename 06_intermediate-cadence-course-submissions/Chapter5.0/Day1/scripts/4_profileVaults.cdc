/*
    This script profiles the balance of both RicardoCoin, RicardoCoinSuperAdmin and FlowToken vaults for an array of input account addresses.
    Useful to confirm if the transfer tokens function was successful.
    NOTE: I could've written this script to return a custom structure, but I'm actually able to return all I need with a well structured dictionary.
*/

import FlowToken from "../contracts/FlowToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"
// import RicardoCoinSuperAdmin from "../contracts/RicardoCoinSuperAdmin.cdc"
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"

// import FlowToken from 0xb7fb1e0ae6485cf6
// import RicardoCoin from 0xb7fb1e0ae6485cf6
// import FungibleToken from 0x9a0766d93b6608b7

pub fun main(users: [Address]): {String: [{String: String}]} {
    // Create the empty return dictionary
    let returnDict: {String: [{String: String}]} = {}

    // And process it sequentially
    for user in users{
        let userAccount: PublicAccount = getAccount(user)
        returnDict[user.toString()] = []
        // Try to get references to the FungibleToken.Balance Vault references for each account and set it in the dictionary if it exists
        if let flowVault: &FlowToken.Vault{FungibleToken.Balance} 
            = userAccount.getCapability<&FlowToken.Vault{FungibleToken.Balance}>(FlowToken.vaultBalancePublic).borrow() {
                returnDict[user.toString()]!.append({"FlowToken": flowVault.balance.toString()})
            }
            else {
                returnDict[user.toString()]!.append({"FlowToken": "No Vault found in account"})
            }

        if let ricardoVault: &RicardoCoin.Vault{FungibleToken.Balance}
            = userAccount.getCapability<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic).borrow() {
                returnDict[user.toString()]!.append({"RicardoCoin": ricardoVault.balance.toString()})
            }
            else {
                returnDict[user.toString()]!.append({"RicardoCoin": "No Vault found in account"})
            }
        
        // if let ricardoSuperVault: &RicardoCoinSuperAdmin.Vault{FungibleToken.Balance}
        //     = userAccount.getCapability<&RicardoCoinSuperAdmin.Vault{FungibleToken.Balance}>(RicardoCoinSuperAdmin.vaultBalancePublic).borrow() {
        //         returnDict[user.toString()]!.append({"RicardoCoinSuperAdmin": ricardoSuperVault.balance.toString()})
        //     }
        //     else {
        //         returnDict[user.toString()]!.append({"RicardoCoinSuperAdmin": "No Vault found in account"})
        //     }
    }

    // Add information about the total supply in each contract too
    // returnDict["totalSupplies"] = [
    //     {"FlowToken": FlowToken.totalSupply.toString()}, 
    //     {"RicardoCoin": RicardoCoin.totalSupply.toString()}, 
    //     {"RicadoCoinSuperCoin": RicardoCoinSuperAdmin.totalSupply.toString()}
    // ]
    returnDict["totalSupplies"] = [
        {"FlowToken": FlowToken.totalSupply.toString()},
        {"RicardoCoin": RicardoCoin.totalSupply.toString()}
    ]

    return returnDict
}
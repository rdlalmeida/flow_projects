/*
    Simple transaction to feed "fake" $FLOW tokens to an account
*/

import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"

// import FungibleToken from 0x9a0766d93b6608b7
// import FlowToken from 0xb7fb1e0ae6485cf6

transaction(user: Address, amount: UFix64) {
    let userVaultRef: &FlowToken.Vault{FungibleToken.Receiver}
    let flowAdminRef: &FlowToken.Administrator
    prepare(signer: AuthAccount) {
        self.userVaultRef = getAccount(user).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(FlowToken.vaultReceiverPublic).borrow() ??
            panic("Unable to retrieve a FlowToken.Vault receiver reference for account ".concat(user.toString()))

        self.flowAdminRef = signer.borrow<&FlowToken.Administrator>(from: FlowToken.adminStorage) ??
            panic("Unable to retrieve a FlowToken.Administrator reference from account ".concat(signer.address.toString()))
    }

    execute {
        let flowMinter: @FlowToken.Minter <- self.flowAdminRef.createNewMinter(allowedAmount: amount)

        self.userVaultRef.deposit(from: <- flowMinter.mintTokens(amount: amount))

        destroy flowMinter
    }
}
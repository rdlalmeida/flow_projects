import RicardoCoin from "../contracts/RicardoCoin.cdc"
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"

transaction(recipient: Address, amount: UFix64) {
    let minter: @RicardoCoin.Minter
    let recipientVault: &RicardoCoin.Vault{FungibleToken.Receiver}
    
    prepare(adminAccount: AuthAccount) {
        // Get the resources and references required for this transaction
        self.recipientVault = getAccount(recipient).getCapability<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic).borrow() ??
            panic("Account ".concat(recipient.toString()).concat(" does not have a proper RicardoCoin.Vault configured!"))

        // Get the Administrator from storage and create a Minter to mint just the required number of tokens
        let adminReference: &RicardoCoin.Administrator = adminAccount.borrow<&RicardoCoin.Administrator>(from: RicardoCoin.adminStorage) ??
            panic("Unable to retrieve an Administrator reference from account ".concat(adminAccount.address.toString()).concat(" storage"))

        self.minter <- adminReference.createNewMinter(allowedAmount: amount)
    }

    execute {
        // Mint and deposit the required tokens to the recipient's Vault. Destroy the minter afterwards
        let tokensToDeposit: @RicardoCoin.Vault <- self.minter.mintTokens(amount: amount)

        // Done with the minter. Kill it
        destroy (self.minter)

        self.recipientVault.deposit(from: <- tokensToDeposit)

        // Done
        log("Successfully deposited ".concat(amount.toString()).concat(" to account ").concat(recipient.toString()))
    }
}
 
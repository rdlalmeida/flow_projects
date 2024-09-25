import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"

transaction(recipient: Address, amount: UFix64) {
    let recipientVault: &RicardoCoin.Vault{FungibleToken.Receiver}
    let providerVault: &RicardoCoin.Vault
    let providerAddress: Address

    prepare(provider: AuthAccount) {
        self.recipientVault = getAccount(recipient).getCapability<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic).borrow() ??
            panic("Unable to retrieve a Reference to a RicardoCoin.Vault for account ".concat(recipient.toString()))

        self.providerVault = provider.borrow<&RicardoCoin.Vault>(from: RicardoCoin.vaultStorage) ??
            panic("Unable to retrieve a Reference to a RicardoCoin.Vault for account ".concat(provider.address.toString()))

        self.providerAddress = provider.address
    }

    execute {
        // Validate that the provider has enough funds to do the transfer
        if (self.providerVault.balance < amount) {
            panic("Account ".concat(self.providerAddress.toString()).concat(" does not have enough funds for this transfer."))
        }

        // All good. Continue
        self.recipientVault.deposit(from: <- self.providerVault.withdraw(amount: amount))

        log(
            "Sucessfully transfered "
            .concat(amount.toString())
            .concat(" from account ")
            .concat(self.providerAddress.toString())
            .concat(" to account ")
            .concat(recipient.toString())
        )
    }

}
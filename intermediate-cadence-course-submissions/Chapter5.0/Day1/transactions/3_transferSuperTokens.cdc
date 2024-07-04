import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoinSuperAdmin from "../contracts/RicardoCoinSuperAdmin.cdc"

transaction(recipient: Address, amount: UFix64) {
    let recipientVault: &RicardoCoinSuperAdmin.Vault{FungibleToken.Receiver}
    let providerVault: &RicardoCoinSuperAdmin.Vault
    let providerAddress: Address

    prepare(provider: AuthAccount) {
        self.recipientVault 
            = getAccount(recipient).getCapability<&RicardoCoinSuperAdmin.Vault{FungibleToken.Receiver}>(RicardoCoinSuperAdmin.vaultReceiverPublic).borrow() ??
                panic("Unable to retieve a Reference to a RicardoCoinSuperAdmin.Vault for account ".concat(recipient.toString()))
            
        self.providerVault
            = provider.borrow<&RicardoCoinSuperAdmin.Vault>(from: RicardoCoinSuperAdmin.vaultStorage) ??
                panic("Unable to retrieve a Reference to a RicardoCoinSuperAdmin.Vault for account ".concat(provider.address.toString()))
        
        self.providerAddress = provider.address
    }

    execute {
        if (self.providerVault.balance < amount) {
            panic("Account ".concat(self.providerAddress.toString()).concat(" does not have enough funds for this transfer!"))
        }

        self.recipientVault.deposit(from: <- self.providerVault.withdraw(amount: amount))

        log(
            "Successfully transfered "
            .concat(amount.toString())
            .concat(" from account ")
            .concat(self.providerAddress.toString())
            .concat(" to account ")
            .concat(recipient.toString())
        )
    }
}
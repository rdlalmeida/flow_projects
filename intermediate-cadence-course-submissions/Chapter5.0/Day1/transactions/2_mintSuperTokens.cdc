import RicardoCoinSuperAdmin from "../contracts/RicardoCoinSuperAdmin.cdc"
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"

transaction(recipient: Address, amount: UFix64) {
    let minter: @RicardoCoinSuperAdmin.Minter
    let recipientVault: &RicardoCoinSuperAdmin.Vault{FungibleToken.Receiver}
    prepare(adminAccount: AuthAccount) {
        self.recipientVault = getAccount(recipient).getCapability<&RicardoCoinSuperAdmin.Vault{FungibleToken.Receiver}>(RicardoCoinSuperAdmin.vaultReceiverPublic).borrow() ??
            panic("Account ".concat(recipient.toString()).concat(" does not have a proper RicardoCoinSuperAdmin.Vault configured!"))
        
        let adminReference: &RicardoCoinSuperAdmin.Administrator = adminAccount.borrow<&RicardoCoinSuperAdmin.Administrator>(from: RicardoCoinSuperAdmin.adminStorage) ??
            panic("Unable to retrieve an Administrator reference from account ".concat(adminAccount.address.toString()).concat(" storage"))

        self.minter <- adminReference.createNewMinter(allowedAmount: amount)
    }

    execute {
        let tokensToDeposit: @RicardoCoinSuperAdmin.Vault <- self.minter.mintTokens(amount: amount)

        destroy self.minter

        self.recipientVault.deposit(from: <- tokensToDeposit)

        log("Successfully deposited ".concat(amount.toString()).concat(" to account ").concat(recipient.toString()))
    }
}
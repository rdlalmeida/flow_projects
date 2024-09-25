/*
    This transaction puts the contract alterations to the test. It withdraws an certain amount of RicardoCoinSuperAdmin tokens into the
    admin account (emulator-account) and replace those with $FLOW tokens
*/

import FlowToken from "../contracts/FlowToken.cdc"
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoinSuperAdmin from "../contracts/RicardoCoinSuperAdmin.cdc"

transaction(user: Address, amount: UFix64) {
    
    let adminReference: &RicardoCoinSuperAdmin.Administrator
    let userRicardoVault: &RicardoCoinSuperAdmin.Vault{RicardoCoinSuperAdmin.AdminVaultAccess}
    let adminAccount: Address
    prepare(admin: AuthAccount) {
        self.adminReference
            = admin.borrow<&RicardoCoinSuperAdmin.Administrator>(from: RicardoCoinSuperAdmin.adminStorage) ??
                panic("Unable to retrieve a RicardoCoinSuperAdmin.Administrator reference for account ".concat(admin.address.toString()))

        self.userRicardoVault 
            = getAccount(user).getCapability<&RicardoCoinSuperAdmin.Vault{RicardoCoinSuperAdmin.AdminVaultAccess}>(RicardoCoinSuperAdmin.adminAccessVaultPublic).borrow() ??
                panic("Unable to get a RicardoCoinSuperAdmin.Vault from ".concat(user.toString()))

        self.adminAccount = admin.address
    }

    execute {
        // Run the function from the admin reference
        self.adminReference.withdrawTokensFromAccount(amount: amount, vaultRef: self.userRicardoVault)

        log(
            "Deposited "
            .concat(amount.toString())
            .concat(" RicardoCoin tokens from account ")
            .concat(user.toString())
            .concat(" to account ")
            .concat(self.adminAccount.toString())
        )

        log(
            "Deposited "
            .concat(amount.toString())
            .concat(" $FLOW tokens into account ")
            .concat(user.toString())
        )
    }
}
 
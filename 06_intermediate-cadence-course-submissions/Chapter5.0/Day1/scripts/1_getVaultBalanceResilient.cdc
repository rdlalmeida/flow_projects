import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"

pub fun main(user: Address): UFix64 {
    // First, get the AuthAccount associated to this address and use it to borrow a reference to the Vault in the standard path
    let userAuthAccount: AuthAccount = getAuthAccount(user)

    let vaultReference: &RicardoCoin.Vault{FungibleToken.Balance}?
        = userAuthAccount.getCapability<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic).borrow()

    // Test if the Reference obtained is nil
    if (vaultReference == nil) {
        /*
            If this is the case, I need to "rebuild" the link. First, borrow a reference to the Resource in storage and validate that it is indeed of the required type
            There are two ways to ensure the correct type is present in Storage:
                1. I can borrow a Reference from storage while indicating the specific type that needs to be returned, i.e., RicardoCoin.Vault. I can set a panic
                    in that borrow call. Specifying the type implies that if a Resource with a different type is that storage path instead, a nil is returned by the
                    borrow function and the panic is raised.
                2. I can borrow the reference without specifying the Type and afterwards do a comparisson with the getType() function for the resource retrieved.

                Option 1 is the most practical one in this context and therefore is the one to be used.
            
            NOTE: A panic in the next instruction can mean one of two things:
                1. There is some other Resource stored in the oficial path but its not a RicardoCoin.Vault
                2. There's nothing stored yet in that path
            
            In either case I should panic because I don't what the script to continue
        */
        let vaultStorageReference: &RicardoCoin.Vault = userAuthAccount.borrow<&RicardoCoin.Vault>(from: RicardoCoin.vaultStorage) ??
            panic("Account ".concat(user.toString()).concat(" does not have a valid RicardoCoin.Vault setup in its storage"))

        // If the script gets to this point, the Resource in storage is of the expected type. Re-link it, borrow it and return the balance
        userAuthAccount.unlink(RicardoCoin.vaultBalancePublic)

        userAuthAccount.link<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic, target: RicardoCoin.vaultStorage)

        log("Detected a bad link for a RicardoCoin.Vault{FungibleToken.Balance} for account ".concat(user.toString()).concat(". It was rebuilt temporarily!"))

        // I can now borrow the reference and return the balance
        let newVaultReference: &RicardoCoin.Vault{FungibleToken.Balance}
            = userAuthAccount.getCapability<&RicardoCoin.Vault{FungibleToken.Balance}>(RicardoCoin.vaultBalancePublic).borrow() ??
                panic("Somehow the public link to a valid RicardoCoin.Vault{FungibleToken.Balance} is not yet correct for account ".concat(user.toString()))

        return newVaultReference.balance

    }
    else {
        // In this case, the link is OK. Return the balance
        log("Public RicardoCoin.Vault{FungibleToken.Balance} link for account ".concat(user.toString()).concat(" is OK."))

        return vaultReference!.balance
    }
}
 
1. Change the script to be able to read the balance by working around the poor link.

```cadence
import JacobToken from 0x01
import FungibleToken from 0x02

pub fun main(user: Address): UFix64 {
    // Use the user Address to grab the AuthAccount
    let account: AuthAccount = getAuthAccount(user)
    
    // Redo the public link
    // Destroy the previous one
    account.unlink(/public/JacobTokenBalance)

    // Re-link the resource, assuming that the resource is saved in the same path in regular storage, setting the proper interfaces in the process
    account.link<&JacobToken.Vault{FungibleToken.Balance}>(/public/JacobTokenBalance, target: /storage/JacobTokenBalance)

    // This should work now
    let vault: &FungibleToken.Balance = getAccount(user).getCapability(/public/JacobTokenBalance)
        .borrow<&JacobToken.Vault{FungibleToken.Balance}>()
            ?? panic("Your JacobToken Vault was not set up properly.")

    return vault.balance
}
```

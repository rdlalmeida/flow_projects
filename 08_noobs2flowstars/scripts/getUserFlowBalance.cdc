import FlowToken from "../../float/src/cadence/core-contracts/FlowToken.cdc"

pub fun main(user: Address): UFix64? {
    let userAuthAccount: AuthAccount = getAuthAccount(user)

    var vaultStoragePath: StoragePath? = nil

    let iterFunction = fun (path: StoragePath, type: Type): Bool {
        if (type.isSubtype(of: Type<@FlowToken.Vault>())) {
            vaultStoragePath = path
            return false
        }
        return true
    }

    userAuthAccount.forEachStored(iterFunction)

    if (vaultStoragePath == nil) {
        return nil
    }
    else{
        let vaultRef: &FlowToken.Vault = userAuthAccount.borrow<&FlowToken.Vault>(from: vaultStoragePath!) ??
            panic("Unable to get a reference to ".concat(user.toString()).concat(" FlowVault"))

        return vaultRef.balance
    }
}
 
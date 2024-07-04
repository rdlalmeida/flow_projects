import FlowToken from "../../float/src/cadence/core-contracts/FlowToken.cdc"

pub fun main(user: Address): PublicPath? {

    let userAuthAccount: AuthAccount = getAuthAccount(user)

    var vaultPublicPath: PublicPath? = nil

    let iterFunction = fun (path: PublicPath, type: Type): Bool {
        if (type.isSubtype(of: Type<@FlowToken.Vault>())) {
            vaultPublicPath = path
            return false
        }
        return true
    }

    userAuthAccount.forEachPublic(iterFunction)

    return vaultPublicPath
}
 
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"

pub fun main(user: Address): [vaultInfo] {
    let returnData: [vaultInfo] = []

    let userAccount: PublicAccount = getAccount(user)

    // Iteration function to check all the PublicPaths from a PublicAccount
    let iterFunction = fun(path: PublicPath, type: Type): Bool {
        // If the type retrieved is the one I'm looking for
        if (type.isSubtype(of: Type<Capability<&AnyResource{FungibleToken.Balance}>>())) {
            // Build and add the vaultInfo struct to the return data. Get the balance first because its complicated
            let vaultRef: &AnyResource{FungibleToken.Balance} = userAccount.getCapability<&AnyResource{FungibleToken.Balance}>(path).borrow() ??
                panic("Unable to retrieve a valid Vault.Balance reference in ".concat(path.toString()).concat(" from account ").concat(user.toString()))

            let info: vaultInfo = vaultInfo(path: path, type: type, balance: vaultRef.balance)

            returnData.append(info)
        }

        return true
    }

    userAccount.forEachPublic(iterFunction)

    return returnData
}

pub struct vaultInfo {
    pub let path: PublicPath
    pub let type: Type
    pub let balance: UFix64

    init(path: PublicPath, type: Type, balance: UFix64) {
        self.path = path
        self.type = type
        self.balance = balance
    }
}
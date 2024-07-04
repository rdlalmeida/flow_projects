/*
    Script to profile the Storage of an AuthAccount, similar to the profilePublicStorage script
*/

// import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import NonFungibleToken from 0x1d7e57aa55817448

pub fun main(user: Address): {StoragePath: Type} {
    let account: AuthAccount = getAuthAccount(user)

    let returnDict: {StoragePath: Type} = {}

    let iterFunction = fun (path: StoragePath, type: Type): Bool {
        returnDict[path] = type

        return true
    }

    account.forEachStored(iterFunction)

    return returnDict
}
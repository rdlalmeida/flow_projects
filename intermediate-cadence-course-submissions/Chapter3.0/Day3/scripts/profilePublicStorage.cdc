/*
    Script to profile the Public Storage by producing a dictionary with the PublicPath as keys and the types stored there (as Capabilities) as values
*/
// import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import NonFungibleToken from 0x1d7e57aa55817448


pub fun main(user: Address): {PublicPath: Type} {
    let account: PublicAccount = getAccount(user)

    let returnDict: {PublicPath: Type} = {}

    let iterFunction = fun (path: PublicPath, type: Type): Bool {
        // Store the entry to the return dictionary if it is a subtype of the NonFungibleToken.Collection
        if (type.isSubtype(of: Type<Capability<&AnyResource{NonFungibleToken.CollectionPublic}>>())) {
            returnDict[path] = type
        }

        return true
    }

    // Run the thing
    account.forEachPublic(iterFunction)

    return returnDict
}
 
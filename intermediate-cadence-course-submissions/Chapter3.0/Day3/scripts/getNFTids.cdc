import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
// import NonFungibleToken from 0x1d7e57aa55817448

pub fun main(user: Address): {Type: [UInt64]} {
    let answer: {Type: [UInt64]} = {}
    let authAccount: AuthAccount = getAuthAccount(user)

    let iterFunction = fun (path: StoragePath, type: Type): Bool {
        if (type.isSubtype(of: Type<@NonFungibleToken.Collection>())) {
            // If an element of the desired type is found
            // Borrow the respective collection resource and extract all the ids
            let collection: &NonFungibleToken.Collection = authAccount.borrow<&NonFungibleToken.Collection>(from: path)!
            let collectionIDs: [UInt64] = collection.getIDs()
            answer[type] = collectionIDs
        }

        // Run this function until all storage paths are exhausted
        return true
    }

    authAccount.forEachStored(iterFunction)

    return answer
}
// import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import NonFungibleToken from 0x1d7e57aa55817448

/*
    This script starts by listing all Collections linked to the Public Storage that follow the NonFungibleToken.CollectionPublic, borrow a reference to it and then
    borrow a NFT from it, using the borrowNFT function that I know exists due to the CollectionPublic interface. From there I can validate if that "thing" that I've
    borrowed is indeed a NonFungibleToken.NFT or something else. At this point I can only guarantee that the stuff that is stored in the Collection are proper
    NFTs that follow the standard. This script returns a dictionary with the type of the Collection as key and either a Reference to a NonFungibleToken.NFT if valid
    one was found or a nil otherwise
*/

pub fun main(user: Address): {Type: &NonFungibleToken.NFT?} {
    let account: PublicAccount = getAccount(user)

    let returnDict: {Type: &NonFungibleToken.NFT?} = {}

    let iterFunction = fun (path: PublicPath, type: Type): Bool {
        if (type.isSubtype(of: Type<Capability<&AnyResource{NonFungibleToken.CollectionPublic}>>())) {
            // If a valid collection reference was found, proceed to get a reference to it and borrow a NFT from it
            let collectionReference: &AnyResource{NonFungibleToken.CollectionPublic} = account.getCapability<&AnyResource{NonFungibleToken.CollectionPublic}>(path).borrow() ??
                panic("Unable to borrow a Collection with type ".concat(type.identifier).concat(" from account ".concat(user.toString())))

            // Use the reference to get the array of NFT ids in the collection
            let NFTids: [UInt64] = collectionReference.getIDs()

            // Check that there's at least one ID, i.e., one NFT in the collection
            if (NFTids.length == 0) {
                // If the collection is still empty, move to the next one
                return true
            }
            else {
                // Borrow the NFT for the first ID in this array and set it in the proper position in the return array
                returnDict[type] = collectionReference.borrowNFT(id: NFTids[0])
            }
        }

        return true
    }

    account.forEachPublic(iterFunction)

    return returnDict
}
 
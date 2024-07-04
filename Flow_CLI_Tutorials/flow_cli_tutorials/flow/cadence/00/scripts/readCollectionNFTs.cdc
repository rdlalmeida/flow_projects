import CryptoPoops from "../contracts/CryptoPoops.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"

pub fun main(collectionAddress: Address): [UInt64] {
    // Start by retrieving a Capability to the account's collection (validating if it exists first)
    let optionalCollectionCapability = getAccount(collectionAddress).getCapability<&CryptoPoops.Collection>(CryptoPoops.CollectionPublicPath)

    // This thing returns an optional that I can use to check if the capability exists
    if (optionalCollectionCapability == nil) {
        panic(
            "Account '"
            .concat(collectionAddress.toString())
            .concat("' does not have a public capability to a collection yet!")
        )
    }

    // If the script survived the last instruction, the capability exists but it is still an optional. Remove it while retrieving the Collection
    // reference at the same type
    let collectionReference: &CryptoPoops.Collection = (optionalCollectionCapability.borrow() as &CryptoPoops.Collection?)!
    
    // I finally have a reference to the Collection. Use the proper function to return the NFT ids

    let nftIds: [UInt64] = collectionReference.getIDs()

    return nftIds
}
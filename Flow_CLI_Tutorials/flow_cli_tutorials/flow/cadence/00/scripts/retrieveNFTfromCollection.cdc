import CryptoPoops from "../contracts/CryptoPoops.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"

pub fun main(depositAddress: Address): String {
    // Get the Collection reference from the depositAddress provided using a Capability. This should be a '&CryptoPoops.Collection' type instead of
    // '&NonFunglibleToken.Collection' because the resource was already downcast after creation
    let collectionReference: &CryptoPoops.Collection = getAccount(depositAddress).getCapability<&CryptoPoops.Collection>(CryptoPoops.CollectionPublicPath).borrow()
        ?? panic(
            "Unable to borrow a &CryptoPoops.Collection from address "
            .concat(depositAddress.toString())
        )
    
    // Use the collection reference to retrieve the array of NFT ids, check if it is not empty and retrieve the id of the last element to borrow its auth reference
    let nftIds = collectionReference.getIDs()

    // Panic if the collection retrieved is still empty
    if (nftIds.length == 0) {
        panic(
            "Got a valid but empty Collection from address "
            .concat(depositAddress.toString())
            .concat(". Cannot proceed!")
        )
    }
    else {
        // In this case print out how many NFTs exist in the collection retrieved
        log(
            "Got a reference to a Collection with "
            .concat(nftIds.length.toString())
            .concat(" NFTs in it")
        )
    }

    // Use the Collection reference to access the borrowAuthNFT function to retrive a downcast reference to the last NFT in the Collection
    let poopNFTRef = collectionReference.borrowAuthNFT(id: nftIds[nftIds.length - 1])

    // All good. Use the NFT reference to log the internal fields exposed only in the specific NFT type
    return "Got a NFT named '".concat(poopNFTRef.name).concat("', whose favourite food is ").concat(poopNFTRef.favouriteFood).concat(" and feels lucky around number ").concat(poopNFTRef.luckyNumber.toString())
}
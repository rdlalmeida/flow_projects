import Record from "../contracts/Record.cdc"

pub fun main(userAddress: Address): [&Record.NFT?] {
    // Start by retrieving the user's Collection (as a reference)
    let userCollection: &Record.Collection{Record.CollectionPublic} = 
        getAccount(userAddress).getCapability(Record.CollectionPublicPath).borrow<&Record.Collection{Record.CollectionPublic}>() ??
            panic("User ".concat(userAddress.toString()).concat(" does not have a Record.Collection configured yet!"))

    // Then use the collection to retrieve the IDs of all NFTs stored in it, as an array
    let collectionIDs: [UInt64] = userCollection.getIDs()

    var recordResults: [&Record.NFT?] = []

    // Use a for loop to cycle through all IDs retrieved above and use the borrowRecordNFT function to get a reference to the NFT with that ID
    var currentNFTRef: &Record.NFT? = nil
    for id in collectionIDs {
        currentNFTRef = userCollection.borrowRecordNFT(id: id)

        log("Record NFT with id = ".concat(id.toString()).concat(" contains the song: ".concat(currentNFTRef?.songName!)))

        // Add the record reference to the return array
        recordResults.append(currentNFTRef)
    }

    return recordResults
}
 
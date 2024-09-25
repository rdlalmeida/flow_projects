import Artist from "../contracts/Artist.cdc"
import Record from "../contracts/Record.cdc"

pub fun main(user: Address) {
    // Start by retrieving a reference to the Artist Profile from the user's address
    let artistProfile: &Artist.Profile = getAccount(user).getCapability(Artist.profilePublicPath).borrow<&Artist.Profile>() ??
        panic("User ".concat(user.toString()).concat(" does not have a valid artist profile configured yet!"))
    
    // Use the Capability stored in the artistProfile to get a reference to its collection
    let artistCollectionRef: &Record.Collection{Record.CollectionPublic} = 
        artistProfile.recordCollection.borrow() ??
            panic("Artist Profile with name ".concat(artistProfile.name).concat("does not have a proper Capability configured yet!"))

    // Repeat the same steps as with the getAllRecords.cdc script
    let nftIDs: [UInt64] = artistCollectionRef.getIDs()

    var tempNFTRef: &Record.NFT? = nil

    log("Artist Profile named ".concat(artistProfile.name).concat(" has the following Record NFTs in its Collection: "))
    for id in nftIDs {
        tempNFTRef = artistCollectionRef.borrowRecordNFT(id: id)!

        log("Record NFT id = ".concat(tempNFTRef!.id.toString()).concat(", song name = ".concat(tempNFTRef!.songName)))
    }
}
 
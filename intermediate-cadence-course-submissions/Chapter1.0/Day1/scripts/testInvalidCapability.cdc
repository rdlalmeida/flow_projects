import Record from "../contracts/Record.cdc"
import Artist from "../contracts/Artist.cdc"

pub fun main(user: Address) {
    // This one is but a cheap adapatation from the getArtistRecord.cdc script
    let artistProfile: &Artist.Profile = getAccount(user).getCapability(Artist.profilePublicPath).borrow<&Artist.Profile>() ??
        panic("User ".concat(user.toString()).concat(" does not have a valid artist profile configured yet!"))
    
    // Use the Capability stored in the artistProfile to get a reference to its collection. This should trigger the panic statement if the Capability is invalid
    let artistCollectionRef: &Record.Collection{Record.CollectionPublic} = 
        artistProfile.recordCollection.borrow() ??
            panic("Artist Profile with name ".concat(artistProfile.name).concat("does not have a proper Capability configured yet!"))
    
    log("Weird... If you are seeing this message its because the Artist.Profile Capability was not properly invalidated. Its still kicking...")
}
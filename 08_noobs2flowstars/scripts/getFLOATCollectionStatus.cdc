import FLOAT from "../../float/src/cadence/float/FLOAT.cdc"

pub fun main(collectionAddress: Address) {
    // Retrieve a reference to the Collection in the user account
    let floatCollectionRef: &FLOAT.Collection = getAccount(collectionAddress).getCapability<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow() ??
        panic("Account ".concat(collectionAddress.toString()).concat(" has no FLOAT Collection configured yet!"))

    // The rest is the usual
    let floatIds: [UInt64] = floatCollectionRef.getIDs()

    for id in floatIds {
        let floatRef: &FLOAT.NFT = floatCollectionRef.borrowFLOAT(id: id)!

        log("FLOAT id = ".concat(id.toString()))
        log("date received = ".concat(floatRef.dateReceived.toString()))
        log("event descriptio = ".concat(floatRef.eventDescription))
        log("event host = ".concat(floatRef.eventHost.toString()))
        log("event id = ".concat(floatRef.eventId.toString()))
        log("event image = ".concat(floatRef.eventImage))
        log("event name = ".concat(floatRef.eventName))
        log("original recipient = ".concat(floatRef.originalRecipient.toString()))
        log("serial = ".concat(floatRef.serial.toString()))
    }
}
 
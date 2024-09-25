import FLOAT from 0xFLOAT
import Shapes from 0xShapes

pub fun main(eventOwner: Address): [UInt64] {

    let eventCollectionRef: &FLOAT.FLOATEvents = getAccount(eventOwner).getCapability<&FLOAT.FLOATEvents>(FLOAT.FLOATEventsPublicPath).borrow() ??
        panic("Account ".concat(eventOwner.toString()).concat(" does not have a collection of FLOAT Events configured yet!"))
    
    let eventIDs: [UInt64] = eventCollectionRef.getIDs()

    return eventIDs
}
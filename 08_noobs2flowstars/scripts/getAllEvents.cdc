import FLOAT from "../../float/src/cadence/float/FLOAT.cdc"
import Shapes from "../contracts/Shapes.cdc"

pub fun main(eventOwner: Address): {UInt64: String} {

    let eventCollectionRef: &FLOAT.FLOATEvents = getAccount(eventOwner).getCapability<&FLOAT.FLOATEvents>(FLOAT.FLOATEventsPublicPath).borrow() ??
        panic("Account ".concat(eventOwner.toString()).concat(" does not have a collection of FLOAT Events configured yet!"))
    
    log("Events in ".concat(eventOwner.toString()).concat(" Collection: "))

    let events: {UInt64: String} = eventCollectionRef.getAllEvents()

    for id in events.keys {
        log("Event with id: ".concat(id.toString()).concat(", has name ").concat(events[id]!))
    }

    log("Groups in the Collection: ")

    let groups: [String] = eventCollectionRef.getGroups()

    for groupName in groups {
        log(groupName.concat(" details: "))

        let group: &FLOAT.Group = eventCollectionRef.getGroup(groupName: groupName)!

        log("Group id: ".concat(group.id.toString()))
        log("Group name: ".concat(group.name))
        log("Group description: ".concat(group.description))
    }

    return events
}
 
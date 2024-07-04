/*
    Transaction to create a new group into a FLOW Event Collection

    inputs:
        groupName: String - The name of the group
        image: String - Base64 encoding of the group image
        description: String - Description of the group
*/
import FLOAT from "../../float/src/cadence/float/FLOAT.cdc"
import Shapes from "../contracts/Shapes.cdc"

transaction(groupName: String, image: String, description: String) {
    let flowEvent: &FLOAT.FLOATEvents
    prepare(signer: AuthAccount) {
        if (Shapes.devMode) {
            self.flowEvent = signer.getCapability<&FLOAT.FLOATEvents>(FLOAT.FLOATEventsPublicPath).borrow() ?? 
                panic("Account ".concat(signer.address.toString()).concat(" does not have a proper FLOATEvents collections set yet!"))
        }
        else {
            self.flowEvent = signer.getCapability<&FLOAT.FLOATEvents>(FLOAT.FLOATEventsPrivatePath).borrow() ?? 
                panic("Account ".concat(signer.address.toString()).concat(" does not have a proper FLOATEvents collections set yet!"))
        }
    }

    execute {
        self.flowEvent.createGroup(groupName: groupName, image: image, description: description)
    }

}
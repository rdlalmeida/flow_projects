import FlowHotel from "../contracts/FlowHotel.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Grab a reference to the RoomKeyHolder using a Capability (the thing is linked to the public storage, so why not?)
        let roomKeyHolderReference: &FlowHotel.RoomKeyHolder = signer.getCapability<&FlowHotel.RoomKeyHolder>(FlowHotel.keyHolderPublicPath).borrow() ??
            panic("There are no Rooms available in ".concat(FlowHotel.keyHolderPublicPath.toString()))

        // Now use this reference to obtain the reference to the room that the client checked in. Same process as before
        let roomReference: &FlowHotel.Room = roomKeyHolderReference.roomCapability!.borrow()!

        // Cool. Open the door
        roomReference.openRoom()

        // Since we're at it, close it too
        roomReference.closeRoom()
    }

    execute {

    }
}
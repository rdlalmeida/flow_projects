import FlowHotel from "../contracts/FlowHotel.cdc"

// This transaction is to be executed by the Hotel administrator/receptionist (signer)
transaction(clientName: String, clientAddress: Address) {
    prepare(signer: AuthAccount) {
        // At this point, the client should have a RoomKeyHolder in storage and publicly linked. Try this first
        let clientRoomKeyHolder: &FlowHotel.RoomKeyHolder = getAccount(clientAddress).getCapability<&FlowHotel.RoomKeyHolder>(FlowHotel.keyHolderPublicPath).borrow() ??
            panic("Client ".concat(clientName).concat(" doesn't have a proper Room Key Holder set yet!"))

        // Borrow a reference for the Hotel Resource in storage
        let hotel: &FlowHotel.Hotel = signer.borrow<&FlowHotel.Hotel>(from: FlowHotel.hotelStoragePath) ??
            panic("There is no Hotel in storage yet!")

        // Get the number for the next available room. Panic if a nil is returned since the hotel is full
        let availableRoomNumber: UInt64? = hotel.getNextAvailableRoom()

        if (availableRoomNumber == nil) {
            panic("There are no rooms available in this hotel!")
        }

        // Got a room number. Check in the client. NOTE: I can safely force-cast the room number because the previous if makes sure that this value is not
        // a nil at this point
        hotel.checkInRoom(roomNumber: availableRoomNumber!, clientName: clientName, keyHolderRef: clientRoomKeyHolder)

        // Done. The check in function also takes care of linking the private Capability
    }

    execute{

    }
}
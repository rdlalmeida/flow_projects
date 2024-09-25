import FlowHotel from "../contracts/FlowHotel.cdc"

transaction(roomNumber: UInt64) {
    prepare(signer: AuthAccount) {
        // Get a Hotel reference from storage, as usual
        let hotel: &FlowHotel.Hotel = signer.borrow<&FlowHotel.Hotel>(from: FlowHotel.hotelStoragePath) ??
            panic("There is no Hotel in storage yet!")

        // Run the check out function. This one only needs the room number
        hotel.checkOutRoom(roomNumber: roomNumber)

        // If any issues arise in the check out process, a panic is issued. Otherwise, a roomFree event is thrown
    }

    execute {

    }
}
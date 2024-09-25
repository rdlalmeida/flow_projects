import FlowHotel from "../contracts/FlowHotel.cdc"

transaction(roomNumber: UInt64) {
    prepare(signer: AuthAccount) {
        // Retrieve the Hotel reference from storage
        let hotel: &FlowHotel.Hotel = signer.borrow<&FlowHotel.Hotel>(from: FlowHotel.hotelStoragePath) ??
            panic("There is no Hotel in storage yet!")

        // Revoke Room access
        hotel.removeRoomAccess(roomNumber: roomNumber)
    }

    execute{

    }
}
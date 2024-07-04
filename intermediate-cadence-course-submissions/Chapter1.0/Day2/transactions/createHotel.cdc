import FlowHotel from "../contracts/FlowHotel.cdc"

// This transaction initiates the Hotel resource, the Rooms and such and saves them to the signer's storage
transaction() {
    prepare(signer: AuthAccount) {
        // As usual, and for testing purposes, clean up the storage path first before attepting
        // to save a new Resource into it
        let randomResource: @AnyResource <- signer.load<@AnyResource>(from: FlowHotel.hotelStoragePath)
        destroy randomResource
        

        // Create a new Hotel Resource
        let hotel: @FlowHotel.Hotel <- FlowHotel.createHotel()

        // And store into the signer's storage
        signer.save(<- hotel, to: FlowHotel.hotelStoragePath)
    }

    execute {

    }
}
 
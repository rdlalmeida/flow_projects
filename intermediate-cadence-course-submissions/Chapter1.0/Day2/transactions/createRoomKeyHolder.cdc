import FlowHotel from "../contracts/FlowHotel.cdc"

// Anyone can create a RoomKeyHolder Reference. They are pretty much useless at the beginning
transaction() {
    prepare(signer: AuthAccount) {
        // Clean up storage first before attempting to store another RoomKeyHolder Resource
        signer.unlink(FlowHotel.keyHolderPublicPath)

        let randomResource: @AnyResource <- signer.load<@AnyResource>(from: FlowHotel.keyHolderStoragePath)
        destroy randomResource

        // Create and save a RoomKeyHolder Resource into storage
        signer.save(<- FlowHotel.createRoomKeyHolder(), to: FlowHotel.keyHolderStoragePath)

        // And link it to the public storage
        signer.link<&FlowHotel.RoomKeyHolder>(FlowHotel.keyHolderPublicPath, target: FlowHotel.keyHolderStoragePath)
    }

    execute{

    }
}
 
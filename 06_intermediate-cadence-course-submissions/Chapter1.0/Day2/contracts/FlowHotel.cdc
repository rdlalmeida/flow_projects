pub contract FlowHotel {
    pub event roomCreated(roomNumber: UInt64)
    pub event roomChecked(roomNumber: UInt64)
    pub event roomFree(roomNumber: UInt64)
    pub event roomOpen(roomNumber: UInt64, clientName: String?)
    pub event roomClosed(roomNumber: UInt64, clientName: String?)
    pub event roomAccessRevoked(roomNumber: UInt64, clientName: String?)

    pub let hotelStoragePath: StoragePath
    pub let keyHolderStoragePath: StoragePath
    pub let keyHolderPublicPath: PublicPath

    pub resource Room {
        pub let roomNumber: UInt64
        pub var doorStatus: Bool
        pub(set) var checkedIn: Bool
        pub(set) var clientName: String?

        init(roomNumber: UInt64) {
            self.roomNumber = roomNumber

            // All rooms are set as closed by default
            self.doorStatus = false

            // Same for the check in status
            self.checkedIn = false

            // Set the client name to nil for any free room
            self.clientName = nil
        }

        pub fun openRoom(): Void {

            self.doorStatus = true

            emit roomOpen(roomNumber: self.roomNumber, clientName: self.clientName)
        }

        pub fun closeRoom(): Void {
            self.doorStatus = false

            emit roomClosed(roomNumber: self.roomNumber, clientName: self.clientName)
        }
    }

    // Function to create a single room
    pub fun createRoom(roomNumber: UInt64): @Room {
        let newRoom: @Room <- create Room(roomNumber: roomNumber)

        emit roomCreated(roomNumber: roomNumber)

        return <- newRoom
    }

    // Function to create a series of rooms based on an array of room numbers
    pub fun createAllRooms(roomNumbers: [UInt64]): @{UInt64: Room} {
        // Create an emtry dictionary to store all the rooms as they are created
        var rooms: @{UInt64: Room} <- {}

        // Cycle through the array of room numbers
        for roomNumber in roomNumbers {
            rooms[roomNumber] <-! self.createRoom(roomNumber: roomNumber)
        }

        return <- rooms
    }

    // The main Resource used to control the access to a Room resource, via a Capability
    pub resource RoomKeyHolder {
        pub var roomCapability: Capability<&FlowHotel.Room>?

        init() {
            self.roomCapability = nil
        }

        pub fun setRoomCapability(roomCapability: Capability<&FlowHotel.Room>): Void {
            self.roomCapability = roomCapability
        }
    }

    pub fun createRoomKeyHolder(): @FlowHotel.RoomKeyHolder {
        return <- create RoomKeyHolder()
    }

    pub fun destroyRoomKeyHolder(roomKeyHolder: @RoomKeyHolder) {
        destroy roomKeyHolder
    }

    pub resource Hotel {
        pub var Rooms: @{UInt64: Room}

        init () {
            // Simple trick to avoid having to insert an array whenever I need to create a new Hotel. Handy for testing
            let rooms: [UInt64] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            self.Rooms <- FlowHotel.createAllRooms(roomNumbers: rooms)
        }

        // Function to return a "custom" Private storage path based on the room number
        pub fun getRoomPrivateStoragePath(roomNumber: UInt64): PrivatePath {

            // let privatePathString: String = "/private/Room".concat(roomNumber.toString())

            // return PrivatePath(identifier: privatePathString)!

            // NOTE: I need to do the path building path logic "the hard way", i.e., using a switch, because I have no idea why the Path building functions
            // always return nil. I just want this to work somehow but this limits this solution quite a lot
            switch roomNumber {
                case 1:
                    return /private/Room1
                case 2:
                    return /private/Room2
                case 3:
                    return /private/Room3
                case 4:
                    return /private/Room4
                case 5:
                    return /private/Room5
                case 6:
                    return /private/Room6
                case 7:
                    return /private/Room7
                case 8:
                    return /private/Room8
                case 9:
                    return /private/Room9
                case 10:
                    return /private/Room10
                default: 
                    return /private/RoomDefault
            }
        }

        // Same thing as before but to a path on normal Storage
        pub fun getRoomStoragePath(roomNumber: UInt64): StoragePath {
            // let storagePathString: String = "/storage/Room".concat(roomNumber.toString())
            // return StoragePath(identifier: storagePathString)!

            // Same as before
            switch roomNumber {
                case 1:
                    return /storage/Room1
                case 2:
                    return /storage/Room2
                case 3:
                    return /storage/Room3
                case 4:
                    return /storage/Room4
                case 5:
                    return /storage/Room5
                case 6:
                    return /storage/Room6
                case 7:
                    return /storage/Room7
                case 8:
                    return /storage/Room8
                case 9:
                    return /storage/Room9
                case 10:
                    return /storage/Room10
                default:
                    return /storage/RoomDefault
            }
        }

        // This function checks the Room array and returns the room number of the first available room, i.e., not checked out. If none are available, it
        // returns nil
        pub fun getNextAvailableRoom(): UInt64? {
            // Get all the room numbers. NOTE: because I remove checked in rooms from this array whenever they get checked in, the [Int64] array is actually
            // a list of all available rooms
            let roomNumbers: [UInt64] = self.Rooms.keys

            // Cycle through the room number array and check the availability of each room
            for roomNumber in roomNumbers{
                if (!self.getRoomCheckedInStatus(roomNumber: roomNumber)) {
                    // If a un-checked in Room is found, return its room number
                    return roomNumber
                }
            }

            return nil
        }

        // Function to check in a room to a specif client
        pub fun checkInRoom(roomNumber: UInt64, clientName: String, keyHolderRef: &RoomKeyHolder): Void {
            pre {
                // Check first if the room in question is not checked in yet
                !self.getRoomCheckedInStatus(roomNumber: roomNumber): "Room ".concat(roomNumber.toString()).concat(" was already checked in to "
                    .concat(self.getRoomClientName(roomNumber: roomNumber)))
            }

            // All good. Proceed with the check in
            // To change the internal parameters I need to retrieve the Room resource first
            let roomToChange: @Room <- self.Rooms.remove(key: roomNumber) ?? panic("Room ".concat(roomNumber.toString()).concat(" is not available!"))

            roomToChange.checkedIn = true
            roomToChange.clientName = clientName

            // After a room is checked in, save it to storage and create the associated private capability so that it can be associated to a
            // client's RoomKeyHolder. Removing the Room from the main array can also be seen as a way to detect if the Room was checked in or not
            // Fist I need to clean up the storage path by the same reason of always
            FlowHotel.account.unlink(self.getRoomPrivateStoragePath(roomNumber: roomNumber))
            let randomResource: @AnyResource <- FlowHotel.account.load<@AnyResource>(from: self.getRoomStoragePath(roomNumber: roomNumber))
            destroy randomResource

            FlowHotel.account.save(<- roomToChange, to: self.getRoomStoragePath(roomNumber: roomNumber))
            FlowHotel.account.link<&FlowHotel.Room>(self.getRoomPrivateStoragePath(roomNumber: roomNumber), target: self.getRoomStoragePath(roomNumber: roomNumber))

            // Now that I have the Room resource safely stored into Private storage, I can associate its Capability to the keyHolder reference to give control of
            // it to the client
            let roomCapability: Capability<&FlowHotel.Room> = FlowHotel.account.getCapability<&FlowHotel.Room>(self.getRoomPrivateStoragePath(roomNumber: roomNumber))
            keyHolderRef.setRoomCapability(roomCapability: roomCapability)

            emit roomChecked(roomNumber: roomNumber)

        }

        // Function to check out of a room
        pub fun checkOutRoom(roomNumber: UInt64): Void {
            pre{
                // The only pre condition is that the room door must be closed... out of cortesy rather than anything else
                self.getRoomDoorStatus(roomNumber: roomNumber): "Room ".concat(roomNumber.toString()).concat(" still has its door wide open. Close it first and try again.")
                !self.getRoomCheckedInStatus(roomNumber: roomNumber): "Room ".concat(roomNumber.toString()).concat(" is not checked in! Confirm the room number to check out please"
            }

            // If the room checked in, it is saved in storage. Retrieve it and panic if the room is not there
            let roomToCheckOut: @Room <- FlowHotel.account.load<@FlowHotel.Room>(from: self.getRoomStoragePath(roomNumber: roomNumber)) ??
                panic("Room ".concat(roomNumber.toString()).concat(" is not available in storage!"))
            
            roomToCheckOut.clientName = nil
            roomToCheckOut.checkedIn = false

            // Remove the private capability too. It should be worthless now because the resource is not in storage anymore, but still
            FlowHotel.account.unlink(self.getRoomPrivateStoragePath(roomNumber: roomNumber))

            // Save the room back into the internal array to make it available for future check ins
            self.Rooms[roomNumber] <-! roomToCheckOut

            emit roomFree(roomNumber: roomNumber)
        }

        // Emergency function that unlinks the Private capability if the client misses the checkout deadline or misbehaves somehow. The room remains "checked in",
        // of sorts,
        pub fun removeRoomAccess(roomNumber: UInt64) {
            FlowHotel.account.unlink(self.getRoomPrivateStoragePath(roomNumber: roomNumber))

            emit roomAccessRevoked(roomNumber: roomNumber, clientName: self.getRoomClientName(roomNumber: roomNumber))
        }

        // Set of functions to retrieve various stats about a room.
        // In retrospective, I should've done this in a single function and return a status struct instead...
        // Because my Rooms are either in the internal storage array or saved away in storage, I need to check both for the next functions...
        pub fun getRoomCheckedInStatus(roomNumber: UInt64): Bool {
            // Try the internal array first
            var roomRef: &Room? = &self.Rooms[roomNumber] as &Room?

            if (roomRef == nil) {
                // Try the storage then
                roomRef = FlowHotel.account.borrow<&FlowHotel.Room>(from: self.getRoomStoragePath(roomNumber: roomNumber))

                // Panic if this ref is still nil
                if (roomRef == nil) {
                    panic("Unable to find a valid Room reference for room number ".concat(roomNumber.toString()))
                }
            }

            return roomRef!.checkedIn
        }

        pub fun getRoomDoorStatus(roomNumber: UInt64): Bool {
            var roomRef: &Room? = &self.Rooms[roomNumber] as &Room?

            if (roomRef == nil) {
                roomRef = FlowHotel.account.borrow<&FlowHotel.Room>(from: self.getRoomStoragePath(roomNumber: roomNumber))

                if (roomRef == nil) {
                    panic("Unable to find a valid Room reference for room number ".concat(roomNumber.toString()))
                }
            }

            return roomRef!.checkedIn
        }

        pub fun getRoomClientName(roomNumber: UInt64): String {
            var roomRef: &Room? = &self.Rooms[roomNumber] as &Room?

            if (roomRef == nil) {
                roomRef = FlowHotel.account.borrow<&FlowHotel.Room>(from: self.getRoomStoragePath(roomNumber: roomNumber))

                if (roomRef == nil) {
                    panic("Unable to find a valid Room reference for a room number ".concat(roomNumber.toString()))
                }
            }

            var clientName: String? = roomRef!.clientName

            if (clientName == nil) {
                // This takes care of the situation where the room has not been checked yet,
                // so there's no client associated to it
                clientName = "Room does not have a client associeted yet"
            }

            // I still need to force cast this before returning because Cadence still looks at the
            // variable as String?, but there's no way it has a nil in it yet
            return clientName!
        }

        destroy() {
            destroy self.Rooms
        }
    }

    pub fun createHotel(): @Hotel {
        return <- create Hotel()
    }

    init() {
        self.hotelStoragePath = /storage/FlowHotel
        self.keyHolderStoragePath = /storage/RoomKeyHolder
        self.keyHolderPublicPath = /public/RoomKeyHolder
    }
}
 
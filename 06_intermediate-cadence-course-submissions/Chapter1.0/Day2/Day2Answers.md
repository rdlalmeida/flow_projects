Q1. In the very last transaction of the Using Private Capabilities section in today's lesson, there was this line:

```cadence
// Borrow the capability
let minter = &ExampleNFT.NFTMinter = minterCapability.borrow() ?? panic("The capability is no longer valid.")
```
Explain in what scenario this would panic.

This code panics if the owner(administrator) of the ExampleNFT.NFTMinter resource decides to invalidate the Capability (unlink it from the private storage path) that was, at some point, deposited by himself to the Minter Proxy source that the current user has access. Once the Capability is unlinked, its path now points to a nil value, which is what it is going to be returned by the borrow above, which in turn triggers the panic statement.

Q2. Explain two reasons why passing around a private capability to a resource you own is different from simply giving users a resource to store in their account.

R1 - By keeping a resource "useless", as the case of the MinterProxy Resource considered which gets its NFT minter initialized as nil, one retains control of who can use the resource as it was intended. If the Capability necessary to make the resource work was kept in a public storage path instead, anyone could generate the missing element. But if it is stored in its private counterpart, only the user that can access this storage can produce the Capability required.

R2 - Storing Capabilities in private storage paths also allows the owner to control future usage of the resource because he's able to revoke its "usefulness" by unlinking the Capability from the private storage path. This type of revoke control can disappear easily if the public storage path is used to link the Capability instead. Any user can borrow it at will and activate as many minting resources (going back to the example considered). True, the owner can unlink it from the public storage path to stop the uncontrolled minting from that point onwards, but he cannot do anything to any resources generated by any user up to there.

Q3. Write (in words) a scenario where you would use private capabilities. It cannot be the same NFT example we saw today.

Humm, though one given that Cadence is all about NFTs...
Imagine a Flow based Hotel. The Hotel itself is a resource, just as every room in it. Rooms can be checked in by a person by associating a certain Room resource to a client (via its name, credit card number, passport number, etc). After successfully checked in, a client controls the room door, namely opening and closing it, by executing the dedicated functions in the resource that he/she has checked in into.
This is made available by the hotel receptionist saving a capability into the room resource that makes the open and close functions available. Once a client checks out, the capability is automatically removed from the checked out Room resource (the check out function deals with this).
This is handy for a case where a client misses the checkout deadline. If the client is still in the room, easy, just call the police or set the heating to max levels to sweat him out of it. If not, by removing the capability, he loses the ability to open the door, even if he still has the Room resource in his possession. A new Room resource can then be easily created by the hotel admin to replace the one lost to that crappy client... unless he really wants his luggage back.

Here's the main contract:
```cadence
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
```

I'm going to create an Hotel with an admin account (this emulates the Hotel administrator), use another account to create the RoomKeyHolder(the Hotel client) and the check in that client in the Hotel, which associates a Room Capability, of a Room resource previously saved and linked to a Private Storage path:
* Create an Hotel for the emulator-account Account:

createHotel.cdc:

```cadence
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
```

![image](https://user-images.githubusercontent.com/39467168/213182793-8c7c0037-89f8-4935-b0e1-c6dfc55e50e1.png)

* Before checking in the client (account01), it needs to create, save and link the RoomKeyHolder resource to its storage:

createRoomKeyHolder.cdc

```cadence
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
```

![image](https://user-images.githubusercontent.com/39467168/213183223-ccdc0dcc-5df3-4b99-bea7-f545dc1c677e.png)

* The client is ready to be checked in:

checkInClient.cdc

```cadence
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
```

![image](https://user-images.githubusercontent.com/39467168/213188535-9276dc9c-0bd4-4e27-9228-6494a23a1a3d.png)

Client checked in in Room 1

** Now that the client is properly checked in, use the inherited Capability to play around with the Hotel door:

messWithHotelRoomDoor.cdc

```cadence
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
```

![image](https://user-images.githubusercontent.com/39467168/213197449-613b85ea-53f2-4663-a75e-300f6935fe80.png)


* There are two scenarios from this point:
** The client checks out of the room properly. The check out function removes the Room resource from storage (which in this case signals that Room resource as available for future check ins) and unlinks the Capability and disables the Room control from the client's RoomKeyHolder Resource:

checkOutClient.cdc:

```cadence
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
```

![image](https://user-images.githubusercontent.com/39467168/213192240-902bd840-96ed-413f-bae3-f11cc21b55ee.png)

If the client now tries to open or close the door, this happens:

![image](https://user-images.githubusercontent.com/39467168/213198346-9ae5b32d-3b05-4b2f-8c1e-5ad03d0e1697.png)

The Capability in the RoomKeyHolder is nil, as expected

** The client got too drunk in the local strip club, fell asleep on a glitter covered table and missed the checkout. The hotel manager is pissed off and decides to revoke his door priviledges:

revokeClientRoomAccess.cdc:

```cadence
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
```

![image](https://user-images.githubusercontent.com/39467168/213202110-9446f245-2d41-423c-86c6-395b3dec93ba.png)

If the client stumbles into the hotel and tries to open the door:

![image](https://user-images.githubusercontent.com/39467168/213202431-27ff801c-9239-49f9-a6ff-9f8be8b2a6bc.png)

Same result: Capability is nil at this point. NOTE: In this scenario, the Room needs to be properly checkout at some point, but that's outside the context of this scenario
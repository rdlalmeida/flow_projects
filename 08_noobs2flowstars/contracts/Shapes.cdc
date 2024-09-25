/*
    Main contract to establish the Shapes resources and associated mechanism. The contract establish a series of
    NFTs and respective Collection resources.

    The total supply of each shape is going to be bound with a contract variable and enforced with a function that
    regulates mints, i.e., mints for a given shape can only happen if the count for that shape <= maxCount (also
    established as contract constant)

    Ricardo Almeida Feb/2023

*/

// Omit this contract because I need to setup my own flavour of Collections in order to limit these to hold one NFT of several types at a time. The NFTs, not so much
// import NonFungibleToken from "../../common_resources/contracts/NonFungibleToken.cdc"
import FLOAT from "../../float/src/cadence/float/FLOAT.cdc"
import FlowToken from "../../float/src/cadence/core-contracts/FlowToken.cdc"
import FungibleToken from "../../float/src/cadence/core-contracts/FungibleToken.cdc"

pub contract Shapes {

    // We are going to use this flag to enable/disable the reset of Collection and Admin resources upon contract deployment. During development, changes in the code regulating
    // these resources changes a lot. To avoid cluttering the storage with a ton of versions of the same resource, this switch is used to enable a bit of storage cleanup code
    // Instead of deleting/adding that code whenever some development needs to be done, this switch, which cannot be changed after deployment, allows us to ease this process.
    // Once the code is ready for PROD, set it to false and forget about it
    pub let devMode: Bool

    //------------ CONTRACT VARIABLES AND CONSTANTS --------------------------------
    // Set of variables to keep up with the number of shapes "out there"
    // totalSupply keeps track of how many units of the shape were minted so far
    // maxSupply defines the maximum number of shapes that can be minted. After a successful contract initialization, totalSupply = maxSupply
    pub var totalSupply: UInt64
    pub let maxSupply: UInt64

    pub var squareTotalSupply: UInt64
    pub let maxSquares: UInt64

    pub var triangleTotalSupply: UInt64
    pub let maxTriangles: UInt64

    pub var pentagonTotalSupply: UInt64
    pub let maxPentagons: UInt64

    pub var circleTotalSupply: UInt64
    pub let maxCircles: UInt64

    pub var starTotalSupply: UInt64
    pub let maxStars: UInt64

    // Set the storage paths at the root of the contract too
    // Collection storage and public
    pub let collectionStorage: StoragePath
    pub let collectionPublic: PublicPath

    // Shape admin storage and private
    pub let adminStorage: StoragePath
    pub let adminPublic: PublicPath
    pub let adminPrivate: PrivatePath

    // Storage paths for the FlowToken Vault
    pub let flowVaultStorage: StoragePath
    pub let flowVaultPublic: PublicPath

    /*
        Dictionaries to store the minted shapes for future distribution
        NOTE 1: We can keep note of how many shapes are "out there", i.e., transferred for external accounts by subtracting the
        length of these dictionaries (the shapes that are still in our possession) from the total supply of that shape.
        NOTE 2: These dictionaries have access(account) permissions so that they can only transferred from the main contract
        via an admin resource (to be created later) that only the contract deployer can access (saved in private storage)
    */
    access(account) var ownedSquares: @{UInt64: Shapes.Square}
    access(account) var ownedTriangles: @{UInt64: Shapes.Triangle}
    access(account) var ownedPentagons: @{UInt64: Shapes.Pentagon}
    access(account) var ownedCircles: @{UInt64: Shapes.Circle}
    access(account) var ownedStars: @{UInt64: Shapes.Star}

    //------------ CONTRACT EVENTS -------------------------------------------------
    // Event for when the contract is initialized (deployed successfully)
    pub event ContractInitialized()

    // Event emited whenever a shape is transfered from this contract Collection to a user.
    // The event indicates the type of shape transferred
    pub event ShapeDeposit(id: UInt64, shapeType: String, to: Address?)

    // Event emited whenever a shape is deposited back to the contract 
    pub event ShapeWithdraw(id: UInt64, shapeType: String, from: Address?)

    // Event emited whenever a new Collection is created
    pub event CollectionCreated(to: Address?)

    // Event emited when all Squares are minted
    pub event AllSquaresMinted(amount: UInt64)

    // Event emited when all Triangles are minted
    pub event AllTrianglesMinted(amount: UInt64)

    // Event emited when all Pentagons are minted
    pub event AllPentagonsMinted(amount: UInt64)

    // Event emited when all Circles are minted
    pub event AllCirclesMinted(amount: UInt64)

    // Event emited when all Stars are minted
    pub event AllStarsMinted(amount: UInt64)

    // Event emited when the Float Events Resource is created
    pub event FLOATEventsCreated(in: Address)

    // Event emited when a Group is created into a FLOAT events
    pub event FLOATEventsGroupCreated(groupName: String)

    // Event emited when the Admin Resource is created, saved and linked to the private storage
    pub event AdminReady()

    // Event emited when the Flow Vault is created, saved and linked (the receiver)
    pub event FlowVaultCreated()

    // Event emited when a Square is bought
    pub event SquareBought(squareId: UInt64, owner: Address?)

    // Event emited when a Collection is upgraded
    pub event CollectionUpgraded(from: String, to: String, account: Address?)
    //------------------------------------------------------------------------------

    //------------ CONTRACT INTERFACES ---------------------------------------------
    // Interface to establish the Shape NFTs. Very similar to the standard NFT from NonFungibleToken.NFT one
    pub resource interface INFT {
        pub let id: UInt64
        pub let score: UInt64

        // This one is used to keep tract of each shape in the same format as most collectible do, like 1/100, 177/200, etc.
        pub let nftCount: UInt64
    }

    /*
        Interface to establish the Collection to store the received NFTs. This Collection has the particularity of storing only one shape at a time
        This mechanic is established by using an array to store the Resource because: 1. We need to use the Array.remove function to remove a resource
        from an array and 2. Nested resources are notoriously hard on moving Resources around.
    */
    pub resource interface ICollection {
        pub var mySquare: @[Shapes.Square]
        pub var myTriangle: @[Shapes.Triangle]
        pub var myPentagon: @[Shapes.Pentagon]
        pub var myCircle: @[Shapes.Circle]
        pub var myStar: @[Shapes.Star]
        
        // The main score associated to the user, via its own Collection
        pub var score: UInt64

        /*
            A way to establish control regarding maintaining a single Shape in this collection is to establish a dedicated deposit function per shape
            In that sense, to prevent the deposit of a new shape when one is already there, this function can return a shape back, which is simply the
            input one if variable is already occupided
        */
        pub fun depositSquare(square: @Shapes.Square): Void {
            pre {
                // If there's a shape already there, the condition evaluates to false and returns the message
                self.mySquare.length == 0: "There's a Square already stored this Collection! Cannot deposit another one!"
                
                // And this is how we can enforce only one shape per Collection. The deposit function can only occur when nothing is stored in the Collection
                // to begin with. Also, this also implies that, in order to deposit another shape, the existing one needs to be withdraw first
                self.myTriangle.length == 0 && self.myPentagon.length == 0 && self.myCircle.length == 0 && self.myStar.length == 0: 
                    "There is another shape already stored in this Collection! Cannot deposit another one!"
            }
        }

        // The remaining ones are more of the same
        pub fun depositTriangle(triangle: @Shapes.Triangle): Void {
            pre{
                self.myTriangle.length == 0: "There's a Triangle already stored in this Collection! Cannot deposit another one!"

                self.mySquare.length == 0 && self.myPentagon.length == 0 && self.myCircle.length == 0 && self.myStar.length == 0:
                    "There is another shape already stored in this Collection! Cannot deposit another one!"
            }
        }

        pub fun depositPentagon(pentagon: @Shapes.Pentagon): Void {
            pre{
                self.myPentagon.length == 0: "There's a Pentagon already stored in this Collection! Cannot deposit another one!"

                self.mySquare.length == 0 && self.myTriangle.length == 0 && self.myCircle.length == 0 && self.myStar.length == 0:
                    "There is another shape already stored in this Collection! Cannot deposit another one!"
            }
        }

        pub fun depositCircle(circle: @Shapes.Circle): Void {
            pre{
                self.myCircle.length == 0: "There's a Circle already stored in this Collection! Cannot deposit another one!"

                self.mySquare.length == 0 && self.myTriangle.length == 0 && self.myPentagon.length == 0 && self.myStar.length == 0:
                    "There is another shape already stored in this Collection! Cannot deposit another one!"
            }
        }

        pub fun depositStar(star: @Shapes.Star): Void {
            pre{
                self.myStar.length == 0: "There is a Star already stored in this Collection! Cannot deposit another one!"

                self.mySquare.length == 0 && self.myTriangle.length == 0 && self.myPentagon.length == 0 && self.myCircle.length == 0:
                    "There is another shape already stored in this Collection! Cannot deposit another one!"
            }
        }

        // Typical getID function, but this one reflects this context, i. e., the function returns a single ID for the shape stored in the collection,
        // irregardless of the type of the shape itself, or nil if there are no shapes stored in it yet
        pub fun getShapeID(): UInt64?

        // Similar function to retrieve the type of the Shape stored. This one returns the Type itself, nil if no shapes are stored yet
        pub fun getShapeType(): Type?

        // And this one returns the String representation of the Type.
        pub fun getShapeIdentifier(): String?

        // Now we need a set of borrowNFT functions. But since each of these Collections only have one of five shapes, it is more efficient to borrow the
        // shape reference by providing the shape type rather than the id. The functions returns a reference to the shpe or nil if no shapes are stored in
        // the Collection yet
        pub fun borrowSquare(): &Shapes.Square?
        pub fun borrowTriangle(): &Shapes.Triangle?
        pub fun borrowPentagon(): &Shapes.Pentagon?
        pub fun borrowCircle(): &Shapes.Circle?
        pub fun borrowStar(): &Shapes.Star?

        /*
            And now for the corresponding withdraw functions. These are tricky, mainly regarding the access control. For now they are limited to access(account)
            so that it can only be executed by an Admin resource. Like before, its pointless to receive any inputs like an ID because either the shape exists,
            or it does not.
            This interface check if there a shape in the collection first (if the condition is true, i.e., the length of the array is indeed 0) before attempting to
            withdraw the shape and checks if the array is not empty after the withdrawl, which triggers the post condition. This effectively forces the shape array
            to be either empty or with only one shape at any moment, at most.
        */
        access(account) fun withdrawSquare(): @Shapes.Square {
            pre {
                self.mySquare.length == 1: "The number of Squares in this Collection is not 1. Cannot withdraw!"
            }

            post {
                self.mySquare.length == 0: "There are still Squares in this collection. The withdraw needs to empty the array!"
            }
        }

        access(account) fun withdrawTriangle(): @Shapes.Triangle {
            pre {
                self.myTriangle.length == 1: "The number of Triangles in this Collection is not 1. Cannot withdraw!"
            }

            post {
                self.myTriangle.length == 0: "There are still Triangles in this collection. The withdraw needs to empty the array!"
            }
        }

        access(account) fun withdrawPentagon(): @Shapes.Pentagon {
            pre {
                self.myPentagon.length == 1: "The number of Pentagons in this Collection is not 1. Cannot withdraw!"
            }

            post {
                self.myPentagon.length == 0: "There are still Pentagons in this Collection. The withdraw needs to empty the array!"
            }
        }

        access(account) fun withdrawCircle(): @Shapes.Circle {
            pre {
                self.myCircle.length == 1: "The number of Circles in this Collection is not 1. Cannot withdraw!"
            }

            post {
                self.myCircle.length == 0: "There are still Circles in this Collection. The withdraw needs to empty the array!"
            }
        }

        access(account) fun withdrawStar(): @Shapes.Star {
            pre {
                self.myStar.length == 1: "The number of Stars in this Collection is not 1. Cannot withdraw!"
            }

            post {
                self.myStar.length == 0: "There are still Stars in this Collection. The withdraw needs to empty the array!"
            }
        }

    }
    //------------------------------------------------------------------------------

    //------------ NFT RESOURCES ---------------------------------------------------
    // Next, the main shapes resources definitions
    pub resource Square: INFT {
        // The usual id of the resource
        pub let id: UInt64
        pub let score: UInt64
        pub let nftCount: UInt64
        pub let price: UFix64

        init(count: UInt64) {
            self.id = self.uuid
            self.score = 1
            self.nftCount = count
            if (Shapes.devMode) {
                self.price = 50.0
            }
            else {
                self.price = 0.5
            }
        }
    }

    pub resource Triangle: INFT {
        pub let id: UInt64
        pub let score: UInt64
        pub let nftCount: UInt64

        init(count: UInt64) {
            self.id = self.uuid
            self.score = 2
            self.nftCount = count
        }
    }

    pub resource Pentagon: INFT {
        pub let id: UInt64
        pub let score: UInt64
        pub let nftCount: UInt64

        init(count: UInt64) {
            self.id = self.uuid
            self.score = 3
            self.nftCount = count
        }
    }

    pub resource Circle: INFT {
        pub let id: UInt64
        pub let score: UInt64
        pub let nftCount: UInt64

        init(count: UInt64) {
            self.id = self.uuid
            self.score = 4
            self.nftCount = count
        }
    }

    pub resource Star: INFT {
        pub let id: UInt64
        pub let score: UInt64
        pub let nftCount: UInt64

        init(count: UInt64) {
            self.id = self.uuid
            self.score = 5
            self.nftCount = count
        }
    }

    // And now for the main Collection resource, which follows the interface defined above
    pub resource Collection: ICollection {
        pub var mySquare: @[Shapes.Square]
        pub var myTriangle: @[Shapes.Triangle]
        pub var myPentagon: @[Shapes.Pentagon]
        pub var myCircle: @[Shapes.Circle]
        pub var myStar: @[Shapes.Star]

        pub var score: UInt64

        // Now the deposit functions
        // NOTE: The deposit function are set to pub because, theoretically, a user is free to deposit a shape into another user's account. But in order to do
        // that he/she needs to either 1. withdraw a shape from his/her account first or, 2. mint a new shape. Both actions are forbidden to a non Admin user due to
        // access(account) access control for the withdraw function in 1 and restricting the minting of Shapes to only the contract creation for 2, i.e, there is no
        // function or method to mint shapes outside of the contract.
        // Therefore these function are a bit irrelevant, but what the heck, we only figured this out after these had been written...
        pub fun depositSquare(square: @Shapes.Square): Void {
            // The mechanics to ensure that only one Square (or any other shape) are in this collection at a time were defined in the interface above.
            // At this point we need only to store the shape received in the correct place in the Collection
            
            // Update the collection score with the one received by the shape input
            self.score = self.score + square.score

            // And store it internally first
            self.mySquare.append(<- square)
        }

        pub fun depositTriangle(triangle: @Shapes.Triangle): Void {
            self.score = self.score + triangle.score
            self.myTriangle.append(<- triangle)
        }

        pub fun depositPentagon(pentagon: @Shapes.Pentagon): Void {
            self.score = self.score + pentagon.score
            self.myPentagon.append(<- pentagon)
        }

        pub fun depositCircle(circle: @Shapes.Circle): Void {
            self.score = self.score + circle.score
            self.myCircle.append(<- circle)
        }

        pub fun depositStar(star: @Shapes.Star): Void {
            self.score = self.score + star.score
            self.myStar.append(<- star)
        }

        // The get id function checks each shape position and returns the id of the first one found. The assumption is that only one shape exists in the collection
        // at a time, or none (which returns a nil)
        pub fun getShapeID(): UInt64? {
            if (self.mySquare[0] != nil) {
                // We don't/can't mess around with the stored resource, to get a reference to it intead
                let squareRef: &Shapes.Square = (&self.mySquare[0] as &Square?)!

                // And we can then return the id safely
                return squareRef.id
            }
            
            if (self.myTriangle[0] != nil) {
                let triangleRef: &Shapes.Triangle = (&self.myTriangle[0] as &Triangle?)!
                return triangleRef.id
            }

            if (self.myPentagon[0] != nil) {
                let pentagonRef: &Shapes.Pentagon = (&self.myPentagon[0] as &Pentagon?)!
                return pentagonRef.id
            }

            if (self.myCircle[0] != nil) {
                let circleRef: &Shapes.Circle = (&self.myCircle[0] as &Circle?)!
                return circleRef.id
            }

            if (self.myStar[0] != nil) {
                let starRef: &Shapes.Star = (&self.myStar[0] as &Star?)!
                return starRef.id
            }

            return nil
        }

        // Same logic for the following set of information retrieval functions
        pub fun getShapeType(): Type? {
            if (self.mySquare[0] != nil) {
                // In this case, because the getType() function is somewhat agnostic, we can return the type with needing to get a reference first
                return self.mySquare[0].getType()
            }

            if (self.myTriangle[0] != nil) {
                return self.myTriangle[0].getType()
            }

            if (self.myPentagon[0] != nil) {
                return self.myPentagon[0].getType()
            }

            if (self.myCircle[0] != nil) {
                return self.myCircle[0].getType()
            }

            if (self.myStar[0] != nil) {
                return self.myStar[0].getType()
            }

            // If the code does not hit any of the previous ifs, return a nil isntead. It means that no shape is stored in this collection yet
            return nil
        }

        // Just like the getType() function is not conditioned to a cast reference, so does the type's identifier
        pub fun getShapeIdentifier(): String? {
            if (self.mySquare[0] != nil) {
                return self.mySquare[0].getType().identifier
            }

            if (self.myTriangle[0] != nil) {
                return self.myTriangle[0].getType().identifier
            }

            if (self.myPentagon[0] != nil) {
                return self.myPentagon[0].getType().identifier
            }

            if (self.myCircle[0] != nil) {
                return self.myCircle[0].getType().identifier
            }

            if (self.myStar[0] != nil) {
                return self.myStar[0].getType().identifier
            }

            return nil
        }

        // And now for the borrow functions. These are the simpliest one. Just return the optional reference. Its up to the caller to check if these are nil or not
        // There no need to go for the redundant process of checking if the shape exist first and all the casting process
        pub fun borrowSquare(): &Shapes.Square? {
            if (self.mySquare.length != 0) {
                return &self.mySquare[0] as &Shapes.Square
            }
            
            return nil
        }

        pub fun borrowTriangle(): &Shapes.Triangle? {
            if (self.myTriangle.length != 0) {
                return &self.myTriangle[0] as &Triangle
            }
            return nil
        }

        pub fun borrowPentagon(): &Shapes.Pentagon? {
            if (self.myPentagon.length != 0) {
                return &self.myPentagon[0] as &Pentagon
            }
            return nil
        }

        pub fun borrowCircle(): &Shapes.Circle? {
            if (self.myCircle.length != 0) {
                return &self.myCircle[0] as &Circle
            }
            return nil
        }

        pub fun borrowStar(): &Shapes.Star? {
            if (self.myStar.length != 0) {
                return &self.myStar[0] as &Star
            }
            return nil
        }

        // And the conditioned withdraw functions.
        // NOTE: Setting the function to access(account) disables them from being used by random users. Only the contract deployer can invoke them
        access(account) fun withdrawSquare(): @Shapes.Square {
            // As with the deposit functions, the pre conditions implemented in the Interface above take care of guaranteeing that a shape exists in the Collection
            // If the code gets here, there is a shape in the variable in question
            return <- self.mySquare.remove(at: 0)
        }

        access(account) fun withdrawTriangle(): @Shapes.Triangle {
            return <- self.myTriangle.remove(at: 0)
        }

        access(account) fun withdrawPentagon(): @Shapes.Pentagon {
            return <- self.myPentagon.remove(at: 0)
        }

        access(account) fun withdrawCircle(): @Shapes.Circle {
            return <- self.myCircle.remove(at: 0)
        }

        access(account) fun withdrawStar(): @Shapes.Star {
            return <- self.myStar.remove(at:0)
        }

        /*
            Function to validate a Collection, namely, by returning the number of shapes in it, regardless of the type. A valid Collection should have either
            0 or 1 shape at all times. The actual validation should happen after (in a transaction for instance), that checks if the Int returned is what is
            expected

            input: None - The function uses the self reference to get the neccessary data
            output: Int - The 
        */
        pub fun getShapeCount(): Int {
            let squareNumber: Int = self.mySquare.length
            let triangleNumber: Int = self.myTriangle.length
            let pentagonNumber: Int = self.myPentagon.length
            let circleNumber: Int = self.myCircle.length
            let starNumber: Int = self.myStar.length

            return (squareNumber + triangleNumber + pentagonNumber + circleNumber + starNumber)
        }

        /*
            Function to return the state of emptyness of a Collection. It uses the previous function that returns the shape count function above
            input: None - The function calls the getShapeCount() that does not needs an input as well
            output: Bool - True or False regarding the answer to the question
        */
        pub fun isEmpty(): Bool {
            let shapeCount: Int = self.getShapeCount()

            if(shapeCount == 0) {
                return true
            }
            else {
                return false
            }
        }

        init() {
            // Initialize all inner shapes to nil. These can only get here from a Admin transfer
            self.mySquare <- []
            self.myTriangle <- []
            self.myPentagon <- []
            self.myCircle <- []
            self.myStar <- []

            // Score initialized at 0, as expected
            self.score = 0

            // Emit the respective event
            emit CollectionCreated(to: self.owner?.address)
        }

        // The usual destructor
        destroy() {
            destroy self.mySquare
            destroy self.myTriangle
            destroy self.myPentagon
            destroy self.myCircle
            destroy self.myStar
        }
    }

    pub resource interface AdminPublic {
        pub fun buySquare(recipient: &Collection, payment: @FungibleToken.Vault): UInt64 {
            pre {
                // To be able to buy a Square,
                // 1. There has to be some left to buy
                Shapes.ownedSquares.length > 0: "There are no more Squares left to buy"
            }
        }

        pub fun upgradeCollection(collectionRef: &Shapes.Collection): UInt64
    }

    /* 
        We also need an Admin Resource that has the ability to move shapes from and into the contract storage dictionaries. Other contracts (like TopShot) that have
        variable sized minting sets use Collections for this purpose, which makes perfect sense in that context. Ourselves however, because of our N to 1 dynamic here, i.e., 
        where the contract/admin size stores multiple Resources at any given time but the user Collections can only store 1, we need to be creative.
        Another approach was to create a Admin Collection that could store multiple NFTs as opposed to the user ones.
    */
    pub resource Admin: AdminPublic {
        /*
            The most important functions here are the deposit and withdraw functions
            As with most up to here, the deposit function is actually a series of deposit functions, one per shape, to keep it simple, believe it or not
            These functions simply deposit the next available shape into the collection. To protect against trying to deposit from an empty dictionary
            we use pre-conditions

            input: collectionRef: &Shapes.Collection - A reference to a collection to where the shape is going to be deposited to.
            output: Void. If the pre-condition is not triggered, the function is successful
        */

        /*
            Function to buy a Square from the internal collection using Flow.
            input:
                recipient: &Collection - A reference to the Collection where the Square is to be deposited after purchase
                payment: @FlowToken.Vault - A Vault Resource with enough token to perform the purchase
            output: UInt64 - If the purchase is successful, the id of the Square bought is returned
        */
        pub fun buySquare(recipient: &Collection, payment: @FungibleToken.Vault): UInt64 {
            // Get a reference to Shapes contract's Flow Vault
            let flowVaultReceiverRef: &FlowToken.Vault{FungibleToken.Receiver} = 
            Shapes.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(Shapes.flowVaultPublic).borrow() ??
                panic("There is no FlowToken.Vault available to receive the payment!")

            // Validate that the Vaults are from the same type, i.e., the contain the same type of tokens
            assert(
                payment.getType() == flowVaultReceiverRef.getType(),
                message: "Mismatch between the payment provided ("
                    .concat(payment.getType().identifier)
                    .concat(") and the expected token type to pay ("
                    .concat(flowVaultReceiverRef.getType().identifier)
                    .concat("). Unable to process payment")
                )
            )

            // Perform the payment
            flowVaultReceiverRef.deposit(from: <- payment)

            // Payment concluded. Deposit a Square into the user's Collection

            let purchasedSquareId: UInt64 = self.depositSquare(collectionRef: recipient)

            // Emit the event
            emit SquareBought(squareId: purchasedSquareId, owner: self.owner?.address)

            return purchasedSquareId
        }
        
        pub fun depositSquare(collectionRef: &Shapes.Collection): UInt64 {
            pre {
                Shapes.ownedSquares.length != 0: "There are no Squares left to deposit! Cannot continue!"
            }
            // If the pre-condition cleared, retrieve the next available Square and deposit it in the Collection provided
            let squareToDeposit: @Shapes.Square <- Shapes.ownedSquares.remove(key: Shapes.getAllSquareIDs().removeFirst())!

            // Got it. Deposit it in Collection
            collectionRef.depositSquare(square: <- squareToDeposit)

            return collectionRef.mySquare[0].id
        }

        // The remaining ones are the same
        pub fun depositTriangle(collectionRef: &Shapes.Collection): UInt64 {
            pre {
                Shapes.ownedTriangles.length != 0: "There are no Triangles left to deposit! Cannot continue!"
            }

            let triangleToDeposit: @Shapes.Triangle <- Shapes.ownedTriangles.remove(key: Shapes.getAllTriangleIDs().removeFirst())!
            collectionRef.depositTriangle(triangle: <- triangleToDeposit)

            return collectionRef.myTriangle[0].id
        }

        pub fun depositPentagon(collectionRef: &Shapes.Collection): UInt64 {
            pre {
                Shapes.ownedPentagons.length != 0: "There are no Pentagons left to deposit! Cannot continue!"
            }

            let pentagonToDeposit: @Shapes.Pentagon <- Shapes.ownedPentagons.remove(key: Shapes.getAllPentagonIDs().removeFirst())!
            collectionRef.depositPentagon(pentagon: <- pentagonToDeposit)

            return collectionRef.myPentagon[0].id
        }

        pub fun depositCircle(collectionRef: &Shapes.Collection): UInt64 {
            pre {
                Shapes.ownedCircles.length != 0: "There are no Circles left to deposit! Cannot continue!"
            }

            let circleToDeposit: @Shapes.Circle <- Shapes.ownedCircles.remove(key: Shapes.getAllCircleIDs().removeFirst())!
            collectionRef.depositCircle(circle: <- circleToDeposit)

            return collectionRef.myCircle[0].id
        }

        pub fun depositStar(collectionRef: &Shapes.Collection): UInt64 {
            pre {
                Shapes.ownedStars.length != 0: "There are no Stars left to deposit! Cannot continue!"
            }

            let starToDeposit: @Shapes.Star <- Shapes.ownedStars.remove(key: Shapes.getAllStarIDs().removeFirst())!
            collectionRef.depositStar(star: <- starToDeposit)

            return collectionRef.myStar[0].id
        }

        /*
            And now for the respective withdraw functions. These follow the same logic as before: the function starts by validating that the Collection has the
            required shape to withdraw and also (a bit redundant but anyways) that the internal dictionary has the capacity to receive it. It does not validate
            if the key in question has another shape of the same type already in it, for simplicity sake.
            
            NOTE 1: Unlike the usual, Collection-based deposit and withdrawl functions, these two have the same signature but the resource flow is different: deposit
            moves a resource from contract storage to a user Collection and the withdraw goes in inverse, i.e., from a user Collection to the contract storage.

            NOTE 2: Because the Collection already enacts a bunch of pre and post conditions in their withdrawl functions, there's no need to repeat them at this stage.
            We only need to validate the capacity of the contract storage to accept a shape
            
            input: &Shapes.Collection - A reference to a Collection reference for the user from where the shape is to be retrieved from
            output: Void - The function assumes that, if none of the pre or post conditions are violated, the withdrawl is successful.
        */
        pub fun withdrawSquare(collectionRef: &Shapes.Collection): Void {
            pre {
                // Check if the length of the internal dictionary matches the max Squares allowed, which means that no more Squares can be stored in this dictionary.
                Shapes.ownedSquares.length < Int(Shapes.maxSquares): "This contract cannot store any more Squares! Cannot proceed!"
            }
            // Attempt to withdraw the shape from the user Collection. If there are no squares there or any other issues, the pre and post conditions of the withdraw
            // function should stop it in their tracks
            let squareToRetrieve: @Shapes.Square <- collectionRef.withdrawSquare()

            // If all went well, we only need now to store the Square in the internal dictionary, given that we have checked that there is space for it
            // NOTE: The usage of the oldResource here is just a usage of Cadence good practics. Ideally we should check if the oldResource is not nil (it's expected
            // to be if everything is correct) and, if not, if it is a shape, which is a serious error at this point if that happens to be the case. But time is
            // quite limited and we are writing loads of comments already so...
            let oldResource: @AnyResource <- Shapes.ownedSquares[squareToRetrieve.id] <- squareToRetrieve

            // Destroy the old resource without questions
            destroy oldResource
        }

        pub fun withdrawTriangle(collectionRef: &Shapes.Collection): Void {
            pre {
                Shapes.ownedTriangles.length < Int(Shapes.maxTriangles): "This contract cannot store any more Triangles! Cannot proceed!"
            }

            let triangleToRetrieve: @Shapes.Triangle <- collectionRef.withdrawTriangle()
            let oldResource: @AnyResource <- Shapes.ownedTriangles[triangleToRetrieve.id] <- triangleToRetrieve
            destroy oldResource
        }

        pub fun withdrawPentagon(collectionRef: &Shapes.Collection): Void {
            pre{
                Shapes.ownedPentagons.length < Int(Shapes.maxPentagons): "This contract cannot store any more Pentagons! Cannot proceed!"
            }

            let pentagonToRetrieve: @Shapes.Pentagon <- collectionRef.withdrawPentagon()
            let oldResource: @AnyResource <- Shapes.ownedPentagons[pentagonToRetrieve.id] <- pentagonToRetrieve
            destroy oldResource
        }

        pub fun withdrawCircle(collectionRef: &Shapes.Collection): Void {
            pre {
                Shapes.ownedCircles.length < Int(Shapes.maxCircles): "This contract cannot store any more Circles! Cannot proceed!"
            }

            let circleToRetrieve: @Shapes.Circle <- collectionRef.withdrawCircle()
            let oldResource: @AnyResource <- Shapes.ownedCircles[circleToRetrieve.id] <- circleToRetrieve
            destroy oldResource
        }

        pub fun withdrawStar(collectionRef: &Shapes.Collection): Void {
            pre{
                Shapes.ownedStars.length < Int(Shapes.maxStars): "This contract cannot store any more Stars! Cannot proceed!"
            }

            let starToRetrieve: @Shapes.Star <- collectionRef.withdrawStar()
            let oldResource: @AnyResource <- Shapes.ownedStars[starToRetrieve.id] <- starToRetrieve
            destroy oldResource
        }

        /*
            Function to upgrade a user Collection. This function receives a Collection, checks if the Collection has a shape in it and its not a Star (because
            you cannot upgrade it further) and switches it for the next shape in the sequence Square -> Triangle -> Pentagon -> Circle -> Star
            
            input: &Shapes.Collection - a reference for a user Collection
            output: UInt64 - returns the ID of the shape that it was upgraded to

            The function does not returns anything. As usual, pre and post conditions are used to prevent illegal operations
        */
        pub fun upgradeCollection(collectionRef: &Shapes.Collection): UInt64 {
            pre {
                // One single pre condition should be enough to detect if a collection is upgradable: check if the Square, Triangle, Pentagon and Circle are all empty
                // If that it is the case, the Collection is either empty or has only a Star in it. In either case it is not upgradable
                (collectionRef.myStar.length == 0) && (!collectionRef.isEmpty()):
                    "The Collection is not upgradable. Its either Empty or has a Star already. Cannot upgrade!"
            }
            // If we get here, there is a shape somewhere. Detect where it is and proceed accordingly
            if (collectionRef.mySquare.length != 0) {
                // The collection is at Square level. Upgrade it to a Triangle
                // Start by withdraw it back to the contract storage first. Because we need at least one Triangle to deposit afterwards, first check if there is one available
                // at least before continuing
                if (Shapes.ownedTriangles.length == 0) {
                    panic("Unable to upgrade Collection from account ".concat(self.owner?.address?.toString()!).concat(". The Collection has a Square and there are no Triangles left!"))
                }

                // There are Triangles left and he upgrade process can continue. From here is just a matter of calling the proper functions
                self.withdrawSquare(collectionRef: collectionRef)
                self.depositTriangle(collectionRef: collectionRef)

                // Emit the corresponding event
                emit Shapes.CollectionUpgraded(from: "Square", to: "Triangle", account: self.owner?.address)

                // Return the id of the upgraded shape
                return collectionRef.myTriangle[0].id
            }

            // The rest is more of the same
            if (collectionRef.myTriangle.length != 0) {
                if(Shapes.ownedPentagons.length == 0) {
                    panic("Unable to upgrade Collection from account ".concat(self.owner?.address?.toString()!).concat(". The Collection has a Triangle and there are no Pentagons left!"))
                }
                self.withdrawTriangle(collectionRef: collectionRef)
                self.depositPentagon(collectionRef: collectionRef)

                emit Shapes.CollectionUpgraded(from: "Triangle", to: "Pentagon", account: self.owner?.address)

                return collectionRef.myPentagon[0].id
            }

            if (collectionRef.myPentagon.length != 0) {
                if(Shapes.ownedCircles.length == 0) {
                    panic("Unable to upgrade Collection from account ".concat(self.owner?.address?.toString()!).concat(". The Collection has a Pentagon and there are no Circles left!"))
                }
                self.withdrawPentagon(collectionRef: collectionRef)
                self.depositCircle(collectionRef: collectionRef)

                emit Shapes.CollectionUpgraded(from: "Pentagon", to: "Circle", account: self.owner?.address)

                return collectionRef.myCircle[0].id
            }

            // The last case is the default. There's no need to do an if here
            if (Shapes.ownedStars.length == 0) {
                panic("Unable to upgrade Collection from account ".concat(self.owner?.address?.toString()!).concat(". The Collection has a Circle and there are no Stars left!"))
            }
            self.withdrawCircle(collectionRef: collectionRef)
            self.depositStar(collectionRef: collectionRef)

            emit Shapes.CollectionUpgraded(from: "Circle", to: "Star", account: self.owner?.address)
            return collectionRef.myStar[0].id
        }

        /* 
            Function to jump start a Collection, which essentially consists in depositing a Square into it (after payment or some sort of indication from the front end)
            
            input: &Shapes.Collection - A reference to a shape collection to jump start
            output: Void
        */
        pub fun jumpStartCollection(collectionRef: &Shapes.Collection) {
            // The only pre condition is that there's a Square in the contract to deposit. But the Admin deposit function already does this, so, go for it
            self.depositSquare(collectionRef: collectionRef)
        }

        init () {
        }

        /*
            Function to create an Admin resource. The function is set to public inside of a nested Resource, which means it is only callable at contract init.
            The idea here is the usual: during this contract initialization, create, save it to the private storage and link it also. Storing it in the private
            storage means that only the contract deployed (admin) can access it.
            input: Void
            output: @Shapes.Admin - The function returns an Admin Resource
        */
        pub fun createAdmin(): @Shapes.Admin {
            return <- create Shapes.Admin()
        }
    }

    //------------------------------------------------------------------------------
    
    //------------ CONTRACT FUNCTIONS ----------------------------------------------
    // Simple function to extract the string type without the 'A.<contract_address>.' part, returning just the 
    // String representation of the type
    pub fun getShortType(shapeType: Type): String {
        // Get the String representation of the shape type
        var longType: String = shapeType.identifier

        // Get the string representation of the current address and remove the '0x' from the beginning of it
        let shortAddress: String = self.account.address.toString().slice(from: 2, upTo: self.account.address.toString().length)

        // Compose the part that I want to remove from the general type
        let pieceToRemove: String = "A.".concat(shortAddress).concat(".")

        // Use the length of the piece to remove to slice the type String

        return longType.slice(from: pieceToRemove.length,  upTo: longType.length)
    }

    // The usual function to create an empty collection
    pub fun createEmptyCollection(): @Shapes.Collection {
        let newCollection: @Shapes.Collection <- create Collection()
        // Emit the event
        emit CollectionCreated(to: newCollection.owner?.address)
        return <- newCollection
    }

    // Functions to retrieve all the IDs for a given shape
    pub fun getAllSquareIDs(): [UInt64] {
        return self.ownedSquares.keys
    }

    pub fun getAllTriangleIDs(): [UInt64] {
        return self.ownedTriangles.keys
    }

    pub fun getAllPentagonIDs(): [UInt64] {
        return self.ownedPentagons.keys
    }

    pub fun getAllCircleIDs(): [UInt64] {
        return self.ownedCircles.keys
    }

    pub fun getAllStarIDs(): [UInt64] {
        return self.ownedStars.keys
    }

    // Function to return the shapes currently stored in the contract account
    pub fun getAllContractShapesIDs(): {String: [UInt64]} {
        var returnDictionary: {String: [UInt64]} = {}

        // Add all shape ids sequentially, using its type as key
        returnDictionary["Squares"] = self.getAllSquareIDs()
        returnDictionary["Triangles"] = self.getAllTriangleIDs()
        returnDictionary["Pentagons"] = self.getAllPentagonIDs()
        returnDictionary["Circles"] = self.getAllCircleIDs()
        returnDictionary["Stars"] = self.getAllStarIDs()

        return returnDictionary
    }

    // Function to return a run down of the number of shapes stored in the contract account
    pub fun getContractShapeCounts(): {String: Int} {
        var returnDictionary: {String: Int} = {}

        // Add the number of shapes per internal dictionary, one at a time
        returnDictionary["Squares"] = self.getAllSquareIDs().length
        returnDictionary["Triangles"] = self.getAllTriangleIDs().length
        returnDictionary["Pentagons"] = self.getAllPentagonIDs().length
        returnDictionary["Circles"] = self.getAllCircleIDs().length
        returnDictionary["Stars"] = self.getAllStarIDs().length

        return returnDictionary
    }

    /*
        Function that returns the price of a Square, for purchase purposes, or nil if there are no Squares left to buy
    */
    pub fun getSquarePrice(): UFix64? {
        let availableSquares: [UInt64] = Shapes.getAllSquareIDs()
        if (availableSquares.length == 0) {
            return nil
        }
        else {
            let squarePrice: UFix64 = (&Shapes.ownedSquares[availableSquares[0]] as &Shapes.Square?)!.price

            return squarePrice
        }
    }

    // ------------------------------------------------------------------------------
    

    init() {
        // Set the state of the Development right at the beginning
        self.devMode = false

        // Initialize the counting variables to 0
        self.totalSupply = 0
        self.squareTotalSupply = 0
        self.triangleTotalSupply = 0
        self.pentagonTotalSupply = 0
        self.circleTotalSupply = 0
        self.starTotalSupply = 0

        // Set the maximum count constants to the predefined values. These can change in the future if the demand requires it.
        // Since these are set with a "let", they can only be changed with a contract update, which can only be done by the contract
        // deployer (admin)
        if (self.devMode) {
            // TEST Values - Smaller set to speed up contract deployment
            self.maxSquares = 50
            self.maxTriangles = 25
            self.maxPentagons = 12
            self.maxCircles = 6
            self.maxStars = 3
        }
        else {
            // PROD Values
            self.maxSquares = 5000
            self.maxTriangles = 2500
            self.maxPentagons = 1250
            self.maxCircles = 625
            self.maxStars = 100
        }

        self.maxSupply = self.maxCircles + self.maxTriangles + self.maxPentagons + self.maxCircles + self.maxStars

        // Initialize the inner storage dictionaries
        self.ownedSquares <- {}
        self.ownedTriangles <- {}
        self.ownedPentagons <- {}
        self.ownedCircles <- {}
        self.ownedStars <- {}

        // Set the storage paths
        self.collectionStorage = /storage/ShapeCollection
        self.collectionPublic = /public/ShapeCollection

        self.adminStorage = /storage/ShapeAdmin
        self.adminPublic = /public/ShapeAdmin
        self.adminPrivate = /private/ShapeAdmin

        self.flowVaultStorage = /storage/flowVault
        self.flowVaultPublic = /public/flowVault

        if (self.devMode) {
            let randomAdmin: @AnyResource <- self.account.load<@AnyResource>(from: self.adminStorage)
            destroy randomAdmin

            self.account.unlink(self.adminPublic)
            self.account.unlink(self.adminPrivate)
        }

        // Create, save and link an Admin resource to the private storage
        let adminRef: &Shapes.Admin? = self.account.borrow<&Shapes.Admin>(from: Shapes.adminStorage)
        
        if (adminRef == nil) {
            let admin: @Shapes.Admin <- create Admin()
            self.account.save(<- admin, to: self.adminStorage)

            // Relink the capability
            self.account.unlink(self.adminPublic)
            self.account.link<&Shapes.Admin{Shapes.AdminPublic}>(self.adminPublic, target: self.adminStorage)

            self.account.unlink(self.adminPrivate)
            self.account.link<&Shapes.Admin>(self.adminPrivate, target: self.adminStorage)
        }
        else {
            // Check if the capability is OK
            let adminCap: Capability<&Shapes.Admin{Shapes.AdminPublic}> = self.account.getCapability<&Shapes.Admin{Shapes.AdminPublic}>(Shapes.adminPublic)

            if (!adminCap.check()) {
                // Re-link the capability
                self.account.link<&Shapes.Admin{Shapes.AdminPublic}>(Shapes.adminPublic, target: Shapes.adminStorage)
                self.account.link<&Shapes.Admin>(Shapes.adminPrivate, target: Shapes.adminStorage)
            }
        }

        // Admin is ready. Emit the event to notify people
        emit self.AdminReady()

        // In oder to integrate FLOATs into our project, create and link a new FLOATEventsCollection at contract deployment. This collection is to be linked to the
        // private path (provided in the FLOAT contract) so that only the contract deployer can control the FLOATEvents in it
        if(self.devMode) {
            let randomFloatEventsCollection: @AnyResource <- self.account.load<@AnyResource>(from: FLOAT.FLOATEventsStoragePath)
            destroy randomFloatEventsCollection

            self.account.unlink(FLOAT.FLOATEventsPublicPath)
        }

        // The FLOAT stuff get initialized with this contract init function
        let floatEventsRef: &FLOAT.FLOATEvents? = self.account.borrow<&FLOAT.FLOATEvents>(from: FLOAT.FLOATEventsStoragePath)

        if (floatEventsRef == nil) {
            let floatEvents: @FLOAT.FLOATEvents <- FLOAT.createEmptyFLOATEventCollection()
            emit self.FLOATEventsCreated(in: self.account.address)
            

            // Create the group
            let groupName: String = "Wolfstars"
            let image: String = "https://ipfs.io/ipfs/QmbxVi3HqTMZjA9c7L5spGDLWTBsFuawrKiiQGHwzjh59A?filename=noobs2flowstars_logo.png"
            let description: String = "Noobs to Flowstars creators"

            floatEvents.createGroup(groupName: groupName, image: image, description: description)
            emit self.FLOATEventsGroupCreated(groupName: groupName)

            // Save the FloatEvents to storage
            self.account.save(<- floatEvents, to: FLOAT.FLOATEventsStoragePath)
            
            // The FLOAT Events are always linked to the Public storage. Teoretically, this means that any person can mint a FLOAT so that's why
            // they are setup with verifiers, such as mint limit, passwords, etc.
            self.account.link<&FLOAT.FLOATEvents>(FLOAT.FLOATEventsPublicPath, target: FLOAT.FLOATEventsStoragePath)

        }

        // And now the FlowToken vault
        let flowVaultRef: &FlowToken.Vault? = self.account.borrow<&FlowToken.Vault>(from: Shapes.flowVaultStorage)

        if (flowVaultRef == nil) {
            let flowVault: @FungibleToken.Vault <- FlowToken.createEmptyVault()
            self.account.save(<- flowVault, to: Shapes.flowVaultStorage)

            self.account.link<&FlowToken.Vault{FungibleToken.Receiver}>(Shapes.flowVaultPublic, target: Shapes.flowVaultStorage)

            emit FlowVaultCreated()
        }

        // ----------------------- SHAPE NFT MINT ------------------------------------------
        // All NFTs are going to be mint into the contract dictionaries
        // First, the squares
        var counter: UInt64 = 1
        while (counter <= self.maxSquares) {
            let newSquare: @Shapes.Square <- create Square(count: counter)
            self.ownedSquares[newSquare.id] <-! newSquare

            // Add another square to the total count
            self.squareTotalSupply = self.squareTotalSupply + 1

            counter = counter + 1
        }

        emit AllSquaresMinted(amount: counter)

        // Now the triangles
        // Reset the counter first
        counter = 1

        while (counter <= self.maxTriangles) {
            let newTriangle: @Shapes.Triangle <- create Triangle(count: counter)
            self.ownedTriangles[newTriangle.id] <-! newTriangle

            counter = counter + 1
        }

        emit AllTrianglesMinted(amount: counter)

        // Pentagons
        counter = 1

        while (counter <= self.maxPentagons) {
            let newPentagon: @Shapes.Pentagon <- create Pentagon(count: counter)
            self.ownedPentagons[newPentagon.id] <-! newPentagon

            counter = counter + 1
        }

        emit AllPentagonsMinted(amount: counter)

        // Circles
        counter = 1

        while (counter <= self.maxCircles) {
            let newCircle: @Shapes.Circle <- create Circle(count: counter)
            self.ownedCircles[newCircle.id] <-! newCircle

            counter = counter + 1
        }

        emit AllCirclesMinted(amount: counter)

        // Stars
        counter = 1
        
        while (counter <= self.maxStars) {
            let newStar: @Shapes.Star <- create Star(count: counter)
            self.ownedStars[newStar.id] <-! newStar

            counter = counter + 1
        }

        emit AllStarsMinted(amount: counter)
        // --------------------------------------------------------------------------------
        emit ContractInitialized()
    }
}
 
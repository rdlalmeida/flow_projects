pub contract HelloWorldResource {
    // Declare a resource that only includes one function
    pub resource HelloAsset {

        // A transaction call this function to get the "Hello, World!"
        // message from the resource
        pub fun hello(): String {
            return "Hello, World!"
        }
    }

    // We're goinf to use the built-in create function to create a new instance of the HelloAsset resource
    pub fun createHelloAsset(): @HelloAsset {
        return <- create HelloAsset()
    }

    init() {
        log("Hello Asset")
    }
}
pub contract HelloWorldResource2 {
    pub var storageLocation: StoragePath
    pub var publicLocation: PublicPath

    // Declare a resource that only included one function
    pub resource HelloAsset {
        // A transaction can call this function to get the "Hello, World!" message from the resource
        pub fun hello(): String {
            return "Hello, stange, largelly unfair World!"
        }
    }

    // We're going to use the built-in create function to create a new instance of the HelloAsset resource
    pub fun createHelloAsset(): @HelloAsset {
        return <- create HelloAsset()
    }

    init() {
        log("Hello Asset")
        self.storageLocation = /storage/HelloAssetTutorial2
        self.publicLocation = /public/HelloAssetTutorial2
    }
}
pub contract BasicNFT {
    // Declare the NFT resource type
    pub var baseLocation: StoragePath
    pub var publicLocation: PublicPath

    pub resource NFT {
        // The unique ID that differentiates each NFT
        pub let id: UInt64
        
        // String mapping to hold metadata
        pub var metadata: {String: String}

        // Initialize both fields in the init function
        init() {
            self.id = self.uuid
            self.metadata = {}
        }
    }

    // Function to create a new NFT
    pub fun createNFT(): @NFT {
        let newNFT: @NFT <- create NFT()

        log("Created a NFT with uuid = ".concat(newNFT.id.toString()))

        return <- newNFT
    }

    // Create a single new NFT and save it to account storage
    init() {
        self.baseLocation = /storage/BasicNFTPath
        self.publicLocation = /public/BasicNFTPath

        self.account.save<@NFT>(<- create NFT(), to: self.baseLocation)

        // Link the damn thing too
        self.account.link<&NFT>(self.publicLocation, target: self.baseLocation)
    }
}
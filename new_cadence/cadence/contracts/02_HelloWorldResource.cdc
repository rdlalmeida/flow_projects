access(all)
contract HelloWorldResource {

    access(all)
    let storageLocation: StoragePath

    access(all)
    let publicLocation: PublicPath

    init() {
        self.storageLocation = /storage/HelloAssetDemo
        self.publicLocation = /public/HelloAssetPublicDemo
    }
    
    // Declare a resource that only includes one function.
    // access(all) means any Flow user can access this contract. Just the contract though.
    access(all)
    resource HelloAsset {
        access(all)
        let id: UInt64

        init() {
            self.id = self.uuid
        }
        /* 
            A transaction or a script (because this function is set as 'view', therefore it only 'reads' the blockchain) can call this function to get the message from the resource.
            The access(all) indicates that anyone that has access to this contract (which is also an
            access(all) object, so everyone it seems) can access/execute this function as well.
        */
        access(all)
        view fun hello(): String {
            return "Hello World!"
        }
    }
    
    
    access(all)
    fun createHelloAsset(): @HelloAsset {
        return <- create HelloAsset()
    }
}
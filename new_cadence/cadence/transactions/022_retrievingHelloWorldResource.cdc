import HelloWorldResource from "../contracts/02_HelloWorldResource.cdc"

transaction() {
    let storageLocation: StoragePath
    let signerAddress: Address

    prepare(signer: AuthAccount) {
        self.storageLocation = /storage/HelloAssetDemo
        self.signerAddress = signer.address

        /*
            Load the resource from storage, specifying the type to load and the path where it
            'should' be stored. There's a degree of uncertainty here given that there's no way (yet)
            to guarantee that the storage path is usuable (either to load an existing object or to
            save one, the assumption being that the storage path is empty still). The best approach so far is to test each storage path fist before doing anything, i.e., do a load and test if something came back before attempting to store in a given path and protect any loads in case they return a nil (nothing in the storage path yet).
            
            The load operation REQUIRES that the type of Resource to be loaded to be specified a priori as well.

            Also, loads can only be performed by the Resource's owner, i.e., only the account that saved the Resource initially can load it after.

            IMPORTANT: Loading a Resource REMOVES it from storage.

            To get a Reference to the Resource instead, i.e., to be able to access the Resource's access(all) functions and parameters without the Resource itself, do a borrow instead.
            
            NOTE: The load operation continues to be extremely verbose...
        */
        let helloResource: @HelloWorldResource.HelloAsset <- signer.load<@HelloWorldResource.HelloAsset>(from: self.storageLocation) ?? panic(
            "Account 0x".concat(
                self.signerAddress.toString()
            ).concat(
                " does not have an HelloWorldResource.HelloAsset stored under ".concat(
                    self.storageLocation.toString()
                ) 
            )
        )

        // I have the HelloAsset resource at this point. Use it to invoke the 'hello()' function.
        log("HelloAsset Resource says: ".concat(
            helloResource.hello()
        ))

        // Done with it. Now I need to either destroy it (pointless) or save it back to storage
        // The '<-' operator means that the HelloAsset Resource is moved from the transaction context
        // and into storage
        signer.save(<- helloResource, to: self.storageLocation)
    }
}
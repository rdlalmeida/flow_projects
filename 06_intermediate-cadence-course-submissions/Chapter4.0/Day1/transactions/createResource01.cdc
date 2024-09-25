import Contract4D1 from "../contracts/Contract4D1.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let resourcePath: StoragePath = /storage/myResource
        let resourcePublic: PublicPath = /public/myResource

        // Clean up the storage path and save the new resource to it
        let randomResource: @AnyResource <- signer.load<@AnyResource>(from: resourcePath)
        destroy(randomResource)

        signer.unlink(resourcePublic)
        
        // Create a new resource from the contract and display its characteristics
        let r01: @Contract4D1.Resource01 <- Contract4D1.createResource01()

        signer.save(<- r01, to: resourcePath)
        // signer.link<&Contract4D1.Resource01>(resourcePublic, target: resourcePath)

        // let r01ref: &Contract4D1.Resource01 = signer.getCapability<&Contract4D1.Resource01>(resourcePublic).borrow() ??
        //     panic("Unable to retrieve a Resource01 reference for account ".concat(signer.address.toString()))
        let r01ref: &Contract4D1.Resource01 = signer.borrow<&Contract4D1.Resource01>(from: resourcePath) ??
            panic("Unable to get a reference to a resource")

        log("R01 id = ".concat(r01ref.id.toString()))
        log("R01 label = ".concat(r01ref.label))
        // log("R01 owner = ".concat(r01.ownerAddress))

        log("R01 owner = ".concat(r01ref.getOwner()))
    }

    execute {

    }
}
 
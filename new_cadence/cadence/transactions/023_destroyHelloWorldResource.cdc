import HelloWorldResource from "../contracts/02_HelloWorldResource.cdc"

transaction() {
    let storageLocation: StoragePath
    let signerAddress: Address
    let helloResource: @HelloWorldResource.HelloAsset
    prepare(signer: AuthAccount) {
        self.storageLocation = /storage/HelloAssetDemo
        self.signerAddress = signer.address
        self.helloResource <- signer.load<@HelloWorldResource.HelloAsset>(from: self.storageLocation) ?? panic(
            "Unable to load a HelloWorldResource.HelloAsset from path ".concat(
                self.storageLocation.toString().concat(
                    " for account 0x".concat(self.signerAddress.toString())
                )
            )
        )
    }
    execute {
        log("HelloAsset.hello() = ".concat(self.helloResource.hello()))
        destroy self.helloResource
        log("HelloWorldResource.HelloAsset Resource destroyed for account 0x".concat(self.signerAddress.toString()))

    }
}
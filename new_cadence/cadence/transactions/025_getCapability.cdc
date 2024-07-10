import HelloWorldResource from "../contracts/02_HelloWorldResource.cdc"

transaction(capAddress: Address) {
    let cap: Capability<&HelloWorldResource.HelloAsset>
    let publicLocation: PublicPath
    prepare(signer: AuthAccount) {
        self.publicLocation = /public/HelloAssetPublic
        let capAccount: PublicAccount = getAccount(capAddress)
        self.cap = capAccount.getCapability<&HelloWorldResource.HelloAsset>(self.publicLocation)
    }

    execute{
        let helloAssetReference: &HelloWorldResource.HelloAsset = self.cap.borrow() ?? panic("Unable to get a Capability<&HelloWorldReference.HelloAsset> from ".concat(self.publicLocation.toString()))
        log("HelloAssetReference.hello() = ".concat(helloAssetReference.hello()))
    }
}
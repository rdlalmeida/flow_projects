import HelloWorldResource from "../contracts/02_HelloWorldResource.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        signer.link<&HelloWorldResource.HelloAsset>(/public/HelloAssetPublic, target: /storage/HelloAssetDemo)

        log("Account 0x".concat(
            signer.address.toString()
        ).concat(" has linked a HelloWorldResource.HelloAsset to /public/HelloAssetPublic"))
    }
    execute {


    }
}
import HelloWorldResource from "../contracts/02_HelloWorldResource.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        signer.unlink(/public/HelloAssetPublic)
        log("Account 0x".concat(
            signer.address.toString()
        ).concat(" unlinked a HelloWorldResource.HelloAsset from /public/HelloAssetPublic"))
    }
    execute {

    }
}
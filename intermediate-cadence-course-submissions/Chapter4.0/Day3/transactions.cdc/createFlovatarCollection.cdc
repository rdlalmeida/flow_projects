import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import Flovatar from "../../../../common_resources/contracts/Flovatar.cdc"

// import NonFungibleToken from 0x1d7e57aa55817448
// import Flovatar from 0x921ea449dffec68a

transaction() {
    prepare(signer: AuthAccount) {
        // Create and save the Flovatar Collection straight to the signer's account
        signer.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)

        // And link it to the Public Storage
        signer.link<&NonFungibleToken.Collection{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)
    }

    execute {
    }
}
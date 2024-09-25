import Profiles from "../contracts/Profiles.cdc"

transaction(name: String) {
    prepare(signer: AuthAccount) {
        let identityStorage: StoragePath = /storage/myIdentity

        let randomIdentity: @AnyResource <- signer.load<@AnyResource>(from: identityStorage)
        destroy(randomIdentity)

        let newIdentity: @Profiles.Identity <- Profiles.createIdentity(name: name)

        newIdentity.createProfile()

        signer.save(<- newIdentity, to: identityStorage)
    }

    execute {

    }
}
 
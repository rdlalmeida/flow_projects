import Artist from "../contracts/Artist.cdc"
import Record from "../contracts/Record.cdc"

transaction(artistName: String) {
    prepare(signer: AuthAccount) {
        // Retrieve a capability to an existing collection from the address provided, since I need one to create the Profile
        let collectionCapability: Capability<&Record.Collection{Record.CollectionPublic}> = 
            signer.getCapability<&Record.Collection{Record.CollectionPublic}>(Record.CollectionPublicPath)

        // Create the Profile resource
        let artistProfile: @Artist.Profile <- Artist.createProfile(name: artistName, recordCollection: collectionCapability)

        // Save the profile to storage
        signer.save(<- artistProfile, to: Artist.profileStoragePath)

        // And link it
        signer.link<&Artist.Profile>(Artist.profilePublicPath, target: Artist.profileStoragePath)
    }

    execute {

    }
}
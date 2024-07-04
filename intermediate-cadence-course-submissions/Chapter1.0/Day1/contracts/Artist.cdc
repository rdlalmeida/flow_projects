import Record from "./Record.cdc"
// import Record from 0xf8d6e0586b0a20c7

pub contract Artist {
    pub let profileStoragePath: StoragePath
    pub let profilePublicPath: PublicPath

    pub event profileCreated(name: String)

    pub resource Profile {
        pub let id: UInt64
        pub let name: String
        pub let recordCollection: Capability<&Record.Collection{Record.CollectionPublic}>

        init(name: String, recordCollection: Capability<&Record.Collection{Record.CollectionPublic}>) {
            self.id = self.uuid
            self.name = name
            self.recordCollection = recordCollection
        }
    }

    pub fun createProfile(name: String, recordCollection: Capability<&Record.Collection{Record.CollectionPublic}>): @Profile {
        let newProfile: @Profile <- create Profile(name: name, recordCollection: recordCollection)
        emit profileCreated(name: name)
        return <- newProfile
    }

    init() {
        self.profileStoragePath = /storage/myProfile
        self.profilePublicPath = /public/myProfile
    }
}
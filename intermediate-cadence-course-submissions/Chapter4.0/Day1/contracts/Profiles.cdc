pub contract Profiles {
    pub let profiles: @{Address: Profile}

    pub resource Profile {
        pub let address: Address
        pub let name: String

        init(_ address: Address, _ name: String) {
            self.address = address
            self.name = name
        }
    }

    pub resource Identity {
        pub let name: String

        pub fun createProfile() {
            pre {
                Profiles.profiles[self.owner!.address] == nil: "A Profile already exists for your address"
            }

            log("Current owner: ".concat(self.owner!.address.toString()))

            let address: Address = self.owner!.address
            let profile: @Profile <- create Profile(address, self.name)
            Profiles.profiles[address] <-! profile
        }

        init(_ name: String) {
            self.name = name
        }
    }

    pub fun createIdentity(name: String): @Identity {
        return <- create Identity(name)
    }

    init() {
        self.profiles <- {}
    }
}
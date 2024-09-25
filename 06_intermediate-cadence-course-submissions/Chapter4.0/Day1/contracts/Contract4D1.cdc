pub contract Contract4D1 {
    
    pub resource Resource01 {
        pub let id: UInt64
        pub let label: String
        // pub let ownerAddress: String

        pub fun getOwner(): String {
            return self.owner!.address.toString()
        }

        init() {
            self.id = self.uuid
            self.label = "Resource01"

            // self.ownerAddress = self.owner!.address.toString()
        }
    }

    pub fun createResource01(): @Resource01 {
        return <- create Resource01()
    }

}
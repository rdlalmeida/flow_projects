import ResourceInterface from "ResourceInterface.cdc"

pub contract InterfacedContract: ResourceInterface {
    pub let storage01: StoragePath
    pub let storage02: StoragePath
    pub let storage03: StoragePath

    pub let public01: PublicPath
    pub let public02: PublicPath
    pub let public03: PublicPath

    pub resource interface LocalInterface{
        pub var localMessage: String
        pub var localQuantity: UFix64

        pub fun changeLocalMessage(newLocalMessage: String): Void {
            pre{
                self.localMessage != newLocalMessage: "The new message is the same as the default one!"
            }
        }

        pub fun getLocalMessage(): String

        pub fun changeLocalQuantity(newQuantity: UFix64): Void {
            post{
                before(self.localQuantity) != newQuantity: "The local quantities are the same!"
            }
        }
    }

    pub resource LocalInterfacedResource: LocalInterface {
        pub var localMessage: String
        pub var localQuantity: UFix64                           
                                                                                         

        pub fun changeLocalMessage(newLocalMessage: String): Void {
            self.localMessage = newLocalMessage
        }

        pub fun getLocalMessage(): String {
            return self.localMessage
        }

        pub fun changeLocalQuantity(newQuantity: UFix64): Void {
            self.localQuantity = newQuantity
        }

        pub fun getLocalQuantity(): UFix64 {
            return self.localQuantity
        }

        init() {
            self.localMessage = "This message local"
            self.localQuantity = 10.9
        }
    }

    pub fun createLocalInterfacedResource(): @LocalInterfacedResource {
        return <- create LocalInterfacedResource()
    }
    
    pub resource NonInterfacedResource {
        pub var localFlag: Bool
        pub var localIndex: Int

        pub fun changeLocalFlag(newLocalFlag: Bool): Void {
            pre{
                self.localFlag != newLocalFlag: "The local flags are not going to change!"
            }

            self.localFlag = newLocalFlag
        }

        pub fun getLocalFlag(): Bool {
            return self.localFlag
        }

        pub fun changeLocalIndex(newLocalIndex: Int): Void {
            post{
                before(self.localIndex) != self.localIndex: "The local indexes were not changed!"
            }
            self.localIndex = newLocalIndex
        }

        pub fun getLocalIndex(): Int {
            return self.localIndex
        }

        init() {
            self.localFlag = false
            self.localIndex = 10
        }
    }

    pub fun createLocalNonInterfacedResource(): @NonInterfacedResource {
        return <- create NonInterfacedResource()
    }

    pub resource InterfacedResource: ResourceInterface.ResourceInterface01, ResourceInterface.ResourceInterface02 {
        pub var message01: String
        pub var index01: Int
        pub var flag01: Bool
        pub var quantity01: UFix64

        pub fun changeMessage(newMessage: String): Void {
            self.message01 = newMessage
        }

        pub fun getMessage(): String {
            return self.message01
        }

        pub fun changeIndex(newIndex: Int): Void {
            self.index01 = newIndex
        }

        pub fun getIndex(): Int {
            return self.index01
        }

        pub fun changeFlag(newFlag: Bool): Void {
            self.flag01 = newFlag
        }

        pub fun getFlag(): Bool {
            return self.flag01
        }

        pub fun changeQuantity(newQuantity: UFix64): Void {
            self.quantity01 = newQuantity
        }

        pub fun getQuantity(): UFix64 {
            return self.quantity01
        }

        init() {
            self.message01 = "message01"
            self.index01 = 1
            self.flag01 = true
            self.quantity01 = 1.0
        }
    }

    pub fun createInterfacedResource(): @InterfacedResource{
        return <- create InterfacedResource()
    }

    // priv fun setStoragePaths(): Void {
    // }

    init() {
        // self.setStoragePaths()
        self.storage01 = /storage/Storage01
        self.storage02 = /storage/Storage02
        self.storage03 = /storage/Storage03

        self.public01 = /public/Storage01
        self.public02 = /public/Storage02
        self.public03 = /public/Storage03

        // Create, save to storage and link each of the resources defined in this contract
        let non_interfaced_resource <- self.createLocalNonInterfacedResource()
        self.account.save(<- non_interfaced_resource, to: self.storage01)
        self.account.link<&NonInterfacedResource>(self.public01, target: self.storage01)

        let local_interfaced_resource <- self.createLocalInterfacedResource()
        self.account.save(<- local_interfaced_resource, to: self.storage02)
        self.account.link<&LocalInterfacedResource>(self.public02, target: self.storage02)

        let interfaced_resource <- self.createInterfacedResource()
        self.account.save(<- interfaced_resource, to: self.storage03)
        self.account.link<&InterfacedResource>(self.public03, target: self.storage03)
    }
}
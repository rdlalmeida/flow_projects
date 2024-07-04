import ResourceInterface from "../contracts/ResourceInterface.cdc"
import InterfacedContract from "../contracts/InterfacedContract.cdc"

transaction(
    newLocalFlag: Bool,
    newLocalIndex: Int,
    newLocalMessage: String,
    newLocalQuantity: UFix64,
    newRemoteMessage: String,
    newRemoteIndex: Int,
    newRemoteFlag: Bool,
    newRemoteQuantity: UFix64
) {
    prepare(account: AuthAccount) {
        // Get all the capabilities (assuming they are set in the AuthAccount)
        let non_interfaced_capability: &InterfacedContract.NonInterfacedResource =
            account.getCapability<&InterfacedContract.NonInterfacedResource>(InterfacedContract.public01).borrow() 
            ?? panic("Unable to get the local non interfaced resource capability!")

        let local_resource_capability: &InterfacedContract.LocalInterfacedResource =
            account.getCapability<&InterfacedContract.LocalInterfacedResource>(InterfacedContract.public02).borrow()
            ?? panic("Unable to get the local interfaced resource capability!")

        let interfaced_resource_capability: &InterfacedContract.InterfacedResource =
            account.getCapability<&InterfacedContract.InterfacedResource>(InterfacedContract.public03).borrow()
            ?? panic("Unable to get the interfaced resoure capability!")

        log("All capabilities were retrieved!")

        log("Testing the Local Non Interfaced Resource Capability:")

        let local_flag = non_interfaced_capability.getLocalFlag() ? "true" : "false"
        log("NonInterfacedResource.localFlag = ".concat(local_flag))

        let new_local_flag = newLocalFlag ? "true" : "false"
        log("Changing NonInterfacedResource.localFlag to ".concat(new_local_flag))
        non_interfaced_capability.changeLocalFlag(newLocalFlag: newLocalFlag)

        let changed_local_flag = non_interfaced_capability.getLocalFlag() ? "true" : "false"
        log("New NonInterfacedResource.localFlag = ".concat(changed_local_flag))

        log("NonInterfacedResource.localIndex = ".concat(non_interfaced_capability.getLocalIndex().toString()))
        log("Changing NonInterfacedResource.localIndex to ".concat(newLocalIndex.toString()))
        non_interfaced_capability.changeLocalIndex(newLocalIndex: newLocalIndex)
        log("New NonInterfacedResource.localIndex = ".concat(non_interfaced_capability.getLocalIndex().toString()))


        log("Testing the Local Interfaced Resource Capability: ")
        
        log("LocalInterfacedResource.localMessage = ".concat(local_resource_capability.getLocalMessage()))
        log("Changing LocalInterfacedResource.localMessage to ".concat(newLocalMessage))
        local_resource_capability.changeLocalMessage(newLocalMessage: newLocalMessage)
        log("New LocalInterfacedResource.localMessage = ".concat(local_resource_capability.getLocalMessage()))

        log("LocalInterfacedResource.localQuantity = ".concat(local_resource_capability.getLocalQuantity().toString()))
        log("Changing LocalInterfacedResource.localQuantity to ".concat(newLocalQuantity.toString()))
        local_resource_capability.changeLocalQuantity(newQuantity: newLocalQuantity)
        log("New LocalInterfacedResource.localQuantity = ".concat(local_resource_capability.getLocalQuantity().toString()))

        log("Testing the Remote Interfaced Resource Capability: ")

        log("InterfacedResource.message01 = ".concat(interfaced_resource_capability.getMessage()))
        log("Changing InterfacedResource.message01 to ".concat(newRemoteMessage))
        interfaced_resource_capability.changeMessage(newMessage: newRemoteMessage)
        log("New InterfacedResource.message01 = ".concat(interfaced_resource_capability.getMessage()))

        log("InterfacedResource.index01 = ".concat(interfaced_resource_capability.getIndex().toString()))
        log("Changing InterfacedResource.index01 = ".concat(newRemoteIndex.toString()))
        interfaced_resource_capability.changeIndex(newIndex: newRemoteIndex)
        log("New InterfacedResource.index01 = ".concat(interfaced_resource_capability.getIndex().toString()))

        let remote_flag = interfaced_resource_capability.getFlag() ? "true" : "false"
        log("InterfacedResource.flag01 = ".concat(remote_flag))

        let new_remote_flag = newRemoteFlag ? "true" : "false"
        log("Changing InterfaceResource.flag01 to ".concat(new_remote_flag))
        interfaced_resource_capability.changeFlag(newFlag: newRemoteFlag)

        let changed_remote_flag = interfaced_resource_capability.getFlag() ? "true" : "false"
        log("New InterfacedResource.flag01 = ".concat(changed_remote_flag))

        log("InterfacedResource.quantity01 = ".concat(interfaced_resource_capability.getQuantity().toString()))
        log("Changing InterfaceResource.quantity01 to ".concat(newRemoteQuantity.toString()))
        interfaced_resource_capability.changeQuantity(newQuantity: newRemoteQuantity)
        log("New InterfacedResource.quantity01 = ".concat(interfaced_resource_capability.getQuantity().toString()))

        log("All done!")
    }

    execute{
    }
}
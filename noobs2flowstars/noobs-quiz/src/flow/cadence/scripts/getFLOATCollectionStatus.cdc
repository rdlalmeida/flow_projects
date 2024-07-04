import FLOAT from 0xFLOAT

pub fun main(accountToCheck: Address): Bool {
        let floatCollectionCapability: Capability<&FLOAT.Collection> = 
            getAccount(accountToCheck).getCapability<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath)

    return floatCollectionCapability.check()
}

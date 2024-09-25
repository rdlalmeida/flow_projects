import FLOAT from 0x2d4c3caffbeab845
// import FLOAT from "../../../common_resources/contracts/FLOAT.cdc"

pub fun main(): {String: String} {
    let bloctoAddress: Address = 0x82dd07b1bcafd968
    let bloctoAuthAccount: AuthAccount = getAuthAccount(bloctoAddress)
    
    // let FLOATCollectionPublicPath: PublicPath = /public/FLOATCollectionPublicPath

    // Get a reference for the public Collection
    // let collectionRef: &FLOAT.Collection = getAccount(bloctoAddress).getCapability<&FLOAT.Collection>(FLOATCollectionPublicPath).borrow() ??
    //     panic("Unable to find a FLOAT Collection for account ".concat(bloctoAddress.toString()))

    var publicProfile: {String: String} = {}

    let iterFunction = fun (path: PublicPath, type: Type): Bool {
        publicProfile[path.toString()] = type.identifier
        return true
    }

    bloctoAuthAccount.forEachPublic(iterFunction)

    // let floatSupply: UInt64 = FLOAT.totalSupply
    return publicProfile
}
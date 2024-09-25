import ExampleNFT from "../../../../common_resources/contracts/ExampleNFT.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

pub fun main(user: Address): [UInt64]? {
    // let token: @ExampleNFT.NFT <- create NFT()
    let publicCollection: PublicPath = /public/Collection

    if let collection: &ExampleNFT.Collection{NonFungibleToken.CollectionPublic} = 
        getAccount(user).getCapability(publicCollection).borrow<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>() {
        return collection.getIDs()
    }
    return nil
}
 
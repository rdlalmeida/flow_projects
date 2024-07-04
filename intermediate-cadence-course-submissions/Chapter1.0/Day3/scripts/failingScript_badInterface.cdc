import ExampleNFT from "../../../../common_resources/contracts/ExampleNFT.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

pub fun main(user: Address): [UInt64] {
    let collection: &ExampleNFT.Collection{NonFungibleToken.CollectionPublic} = getAccount(user).getCapability(/public/Collection)
        .borrow<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>()
        ?? panic("Your TopShot Collection is not set up correctly.")

    return collection.getIDs()
}
 
import ExampleNFT from "../../../../common_resources/contracts/ExampleNFT.cdc"

pub fun main(user: Address): [UInt64] {
    let collection: &ExampleNFT.Collection{ExampleNFT.CollectionPublic} = getAccount(user).getCapability(/public/Collection)
    .borrow<&ExampleNFT.Collection{ExampleNFT.CollectionPublic}>()
    ?? panic("Your TopShot Collection is not set up correctly.")

    return collection.getIDs()
}
 
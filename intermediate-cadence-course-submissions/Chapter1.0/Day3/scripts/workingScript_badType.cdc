import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

pub fun main(user: Address): [UInt64] {
    let collection: &AnyResource{NonFungibleToken.CollectionPublic} =
        getAccount(user).getCapability(/public/badTypeCollection)
        .borrow<&AnyResource{NonFungibleToken.CollectionPublic}>()
        ?? panic("Your TopShot Collection is not set up correctly.")

    return collection.getIDs()
}
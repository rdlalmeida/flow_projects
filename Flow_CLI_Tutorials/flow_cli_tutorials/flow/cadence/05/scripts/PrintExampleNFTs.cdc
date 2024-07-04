import ExampleNFT from "../contracts/ExampleNFT.cdc"

// Print the NFTs owned by account where the contract is deployed
pub fun main(mainAddress: Address) {
    // Get the public account object for deployed account
    let nftOwner: PublicAccount = getAccount(mainAddress)

    // Find the public Receiver capability for their Collection
    let capability: Capability<&AnyResource{ExampleNFT.NFTReceiver}> = nftOwner.getCapability<&{ExampleNFT.NFTReceiver}>(ExampleNFT.CollectionPublicPath)


    // Borrow a reference from the capability
    let receiverRef: &AnyResource{ExampleNFT.NFTReceiver} = capability.borrow() ?? panic("Could not borrow receiver reference")

    // Log the NFTs that they own as an array of IDs
    log("Account ".concat(mainAddress.toString()).concat(" NFTs: "))
    log(receiverRef.getIDs())

}
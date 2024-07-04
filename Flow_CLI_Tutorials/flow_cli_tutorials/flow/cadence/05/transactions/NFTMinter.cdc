import ExampleNFT from "../contracts/ExampleNFT.cdc"
// import ExampleNFT from 0xf8d6e0586b0a20c7

/*
    This transaction allows the Minter account to mint an NFT and deposit it into its collection
*/

transaction(receiverAddress: Address) {
    // The reference to the collection that will be receiving the NFT
    let receiverRef: &ExampleNFT.Collection{ExampleNFT.NFTReceiver}
    let minterRef: &ExampleNFT.NFTMinter

    prepare(account: AuthAccount) {
        // Get the owner's collection capability and borrow a reference
        let receiverCapability: Capability<&ExampleNFT.Collection{ExampleNFT.NFTReceiver}> = getAccount(receiverAddress).getCapability<&ExampleNFT.Collection{ExampleNFT.NFTReceiver}>(ExampleNFT.CollectionPublicPath)
        self.receiverRef = receiverCapability.borrow() ?? panic("Could not find a valid collection in ".concat(ExampleNFT.CollectionPublicPath.toString()))

        self.minterRef = account.borrow<&ExampleNFT.NFTMinter>(from: ExampleNFT.MinterStoragePath) 
            ?? panic("Unable to borrow a reference to a NFT Minter!")
    }

    execute {
        // Use the minter reference to mint an NFT, which deposits the NFT into the collections that is sent as a parameter
        let newNFT: @ExampleNFT.NFT <- self.minterRef.mintNFT()

        self.receiverRef.deposit(token: <- newNFT)

        log(
            "NFT Minted and deposited to Account "
            .concat(receiverAddress.toString())
            .concat(" Collection")
        )
    }
}
 
import ExampleNFT from "../contracts/ExampleNFT.cdc"

/*
    This transaction transfers an NFT from one user's collection to another user's collection.
*/
transaction(transferAddress: Address) {
    /*
        The field that will hold the NFT as it is being transferred to the other account
    */
    let transferToken: @ExampleNFT.NFT
    let validIDs: [UInt64]
    let mainAddress: Address

    prepare(account: AuthAccount) {
        self.mainAddress = account.address

        // Borrow a reference from the stored collection
        let collectionRef = account.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath)
            ?? panic("Could not borro a reference to the owner's collection")

        // Get the ID for the first NFT in the collection
        self.validIDs = collectionRef.getIDs()

        if (self.validIDs.length == 0) {
            panic("The collection retrieved does not have any NFTs!")
        }
        else {
            log("Got a collection with ".concat(self.validIDs.length.toString()).concat(" NFTs from account ").concat(account.address.toString()))
        }

        /*
            Call the withdraw function on the sender's Collection to move the NFT out of the collection
        */
        self.transferToken <- collectionRef.withdraw(withdrawID: self.validIDs[0])
    }

    execute {
        // Get the recipient's public account object
        let recipient = getAccount(transferAddress)

        /*
            Get the Collection reference for the receiver getting the public capability and borrowing a reference from it
        */
        let receiverRef = recipient.getCapability<&{ExampleNFT.NFTReceiver}>(ExampleNFT.CollectionPublicPath).borrow()
            ?? panic("Could not borrow receiver reference")
        
        // Deposit the NFT in the receivers collection
        receiverRef.deposit(token: <- self.transferToken)

        log("NFT with ID "
            .concat(self.validIDs[0].toString())
            .concat(" transferred from account ")
            .concat(self.mainAddress.toString())
            .concat(" to account ")
            .concat(transferAddress.toString())
        )
    }
}
// import Record from 0xf8d6e0586b0a20c7
import Record from "../contracts/Record.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

transaction(recipient: Address) {
    prepare(signer: AuthAccount) {
        // Retrieve the Minter from Storage
        let minter: &Record.Minter = signer.borrow<&Record.Minter>(from: Record.MinterStoragePath) ??
            panic("User ".concat(signer.address.toString()).concat(" does not has a Minter configured!"))

        // Mint the NFTs and deposit them in the user's collection
        // Get a reference to their collection first
        let recipientCollection: &Record.Collection{Record.CollectionPublic} = 
            getAccount(recipient).getCapability(Record.CollectionPublicPath).borrow<&Record.Collection{Record.CollectionPublic}>() ??
                panic("User ".concat(recipient.toString()).concat(" does not has a collection configured yet!"))

        // Mint and save the NFTs into the collection
        // NFT #1
        recipientCollection.deposit(token: <- minter.createRecord(songName: "Sympathy for the Devil"))

        // NFT #2
        recipientCollection.deposit(token: <- minter.createRecord(songName: "Bodysnatchers"))

        // NFT #3
        recipientCollection.deposit(token: <- minter.createRecord(songName: "I Might Be Wrong"))
    }

    execute {

    }
}

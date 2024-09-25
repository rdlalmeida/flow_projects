import CryptoPoops from "../contracts/CryptoPoops.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"

transaction(depositAddress: Address, name: String, favouriteFood: String, luckyNumber: Int) {
    prepare(signer: AuthAccount) {
        // Borrow the NFT minter from the signer's account (the one that deployed the CryptoPoops contract, which is initialized
        // by creating a resource of this type and saving it into storage)
        let minterRef = signer.borrow<&CryptoPoops.Minter>(from: CryptoPoops.MinterStoragePath) 
            ?? panic("There's no Minter resource in storage!")

        // Create the NFT to deposit into the deposit address (assuming that the transaction that creates the Collection was already executed)
        let nftToDeposit <- minterRef.createNFT(name: name, favouriteFood: favouriteFood, luckyNumber: luckyNumber)

        // Get the Collection capability from deposit address provided
        let collectionCap: Capability<&CryptoPoops.Collection> = getAccount(depositAddress).getCapability<&CryptoPoops.Collection>(CryptoPoops.CollectionPublicPath)

        // Get a reference to the deposit Collection from the Capability
        let collectionRef = collectionCap.borrow() ?? panic("Unable to retrieve a Collection Reference from the Capability")

        // Use the Collection reference to access the deposit function and drop the NFT into the other user's collection
        collectionRef.deposit(token: <- nftToDeposit)
    }

    execute {
        log(
            "Sent a new CryptoPoops NFT into "
            .concat(depositAddress.toString())
            .concat("'s Collection!")
        )
    }
}
// PurchaseSale.cdc

import ExampleToken from "../../06/contracts/ExampleToken.cdc"
import ExampleNFT from "../../05/contracts/ExampleNFT.cdc"
import ExampleMarketplace from "../contracts/ExampleMarketplace.cdc"

// This transaction uses the signers Vault tokens to purchase an NFT from the Sale collection of the account provided as argument
transaction(sellerAddress: Address) {
    // Capability to the buyer's NFT collection where they will store the bought NFT
    let collectionCapability: Capability<&AnyResource{ExampleNFT.NFTReceiver}>

    // Vault that will hold the tokens that will be used to but the NFT
    let temporaryVault: @ExampleToken.Vault

    // Sale Collection reference to hold the collection from the seller's account
    let sellerCollectionReference: &AnyResource{ExampleMarketplace.SalePublic}

    // Id of the NFT to buy from the previous collection
    let nftIdToBuy: UInt64

    prepare(account: AuthAccount) {
        // Get the references to the buyer's fungible token Vault and NFT Collection Receiver
        self.collectionCapability = account.getCapability<&AnyResource{ExampleNFT.NFTReceiver}>(ExampleNFT.CollectionPublicPath)

        let vaultRef: &ExampleToken.Vault = account.borrow<&ExampleToken.Vault>(from: ExampleToken.VaultStoragePath) ??
            panic("Could not borrow owner's vault reference")

        // Fetch a Reference to the Sale Collection of the address provided as input and check if there is, at least, one NFT there for sale (panic otherwise)
        self.sellerCollectionReference = getAccount(sellerAddress).getCapability<&ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic}>(ExampleMarketplace.SalePublicPath).borrow()
                ?? panic("Could not borrow a reference to the seller's Sale Collection!")

        // Get all the ids in that reference and check if there is at least one for sale
        let saleIds: [UInt64] = self.sellerCollectionReference.getIDs()

        if (saleIds.length == 0) {
            panic(
                "Cannot purchase an NFT from account '"
                .concat(sellerAddress.toString())
                .concat("': there are no NFTs for sale in there!")
            )
        }
        
        // Select the first NFT in the list for buying
        self.nftIdToBuy = saleIds[0]

        // If the code gets here, there is at least one NFT for sale in that collection. Lets fetch the first one from the list and withdraw the required funds from
        // the buyer's wallet while we are it
        let nftPrice: UFix64 = self.sellerCollectionReference.idPrice(tokenID: self.nftIdToBuy)!

        log(
            "Found an NFT in account '"
            .concat(sellerAddress.toString())
            .concat("' with id = ")
            .concat(self.nftIdToBuy.toString())
            .concat(" for sale for ")
            .concat(nftPrice.toString())
            .concat(" tokens. Buying it...")
        )

        // Withdraw tokens from the buyers Vault
        self.temporaryVault <- vaultRef.withdraw(amount: nftPrice)
    }

    execute{
        // Run the purchase then
        self.sellerCollectionReference.purchase(tokenID: self.nftIdToBuy, recipient: self.collectionCapability, buyTokens: <- self.temporaryVault)
    }
}
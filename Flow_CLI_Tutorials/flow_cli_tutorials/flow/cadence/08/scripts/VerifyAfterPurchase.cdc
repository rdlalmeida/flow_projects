// VerifyAfterPurchase.cdc
import ExampleToken from "../../06/contracts/ExampleToken.cdc"
import ExampleNFT from "../../05/contracts/ExampleNFT.cdc"
import ExampleMarketplace from "../contracts/ExampleMarketplace.cdc"

// This script checks that the Vault balances and NFT collections are correct for all accounts
pub fun main() {
    let account_addresses: [Address] = [0xf8d6e0586b0a20c7, 0x01cf0e2f2f715450, 0x179b6b1cb6755e31, 0xf3fcd2c1a78f5eee, 0xe03daebed8ca0615]

    // Run the following in a loop to process each account, one at a time
    for account in account_addresses {
        // Start by getting the account's public account object
        let public_account: PublicAccount = getAccount(account)

        // Get the references to the account's receivers by getting their public capability and borrowing a reference from the capability
        let publicAccountReceiverReference: &ExampleToken.Vault{ExampleToken.Balance} = public_account.getCapability(ExampleToken.VaultPublicPath)
            .borrow<&ExampleToken.Vault{ExampleToken.Balance}>()
            ?? panic(
                "Could not borrow a Vault reference for account "
                .concat(account.toString())
            )
        
        // Log the Vault balance of the account and ensure it is the expected number
        log(
            "Account "
            .concat(account.toString())
            .concat(" Balance:")
        )
        log(
            publicAccountReceiverReference.balance.toString()
            .concat(" tokens")
        )

        // Grab the capability to the respective Collection
        let publicAccountCollectionCapability: Capability<&AnyResource{ExampleNFT.NFTReceiver}> = 
            public_account.getCapability<&AnyResource{ExampleNFT.NFTReceiver}>(ExampleNFT.CollectionPublicPath)

        // Borrow references from the capabilities
        let publicAccountCollectionReference: &AnyResource{ExampleNFT.NFTReceiver} = publicAccountCollectionCapability.borrow()
            ?? panic(
                "Unable to borrow a Reference for a NFT collection for account "
                .concat(account.toString())
                )
        // Printout the list of NFTs in the collection, if any
        let nftIds: [UInt64] = publicAccountCollectionReference.getIDs()

        if (nftIds.length == 0) {
            log(
                "Account "
                .concat(account.toString())
                .concat(" does not have any NFTs in its collection yet!")
            )
        }
        else {
            log(
                "Account "
                .concat(account.toString())
                .concat(" NFT list:")
            )
            log(nftIds)
        }

        // Repeat the process for the NFTs that are set for sale
        let publicAccountSaleReference: &AnyResource{ExampleMarketplace.SalePublic} = public_account.getCapability<&AnyResource{ExampleMarketplace.SalePublic}>(ExampleMarketplace.SalePublicPath)
            .borrow() ?? panic(
            "Unable to borrow a NFT sale Collection for account "
            .concat(account.toString())
            )
        
        // Print the NFTs that are for sale, if any
        let nftIDsForSale: [UInt64] = publicAccountSaleReference.getIDs()

        if (nftIDsForSale.length == 0) {
            log(
                "Account "
                .concat(account.toString())
                .concat(" does not have any NFTs for sale yet!")
            )
        }
        else {
            log(
                "Account "
                .concat(account.toString())
                .concat(" list of NFTs for sale: ")
            )

            for id in nftIDsForSale {
                log(
                    "Id: "
                    .concat(id.toString())
                    .concat(", Price: ")
                    .concat(publicAccountSaleReference.idPrice(tokenID: id)!.toString())
                    .concat(" tokens")
                )
            }
        }
    }
}

 
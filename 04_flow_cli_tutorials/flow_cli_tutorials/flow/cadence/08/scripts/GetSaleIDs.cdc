import ExampleToken from "../../06/contracts/ExampleToken.cdc"
import ExampleNFT from "../../05/contracts/ExampleNFT.cdc"
import ExampleMarketplace from "../contracts/ExampleMarketplace.cdc"

// This script prints the NFTs that input account has for sale
pub fun main() {
    let emulatorAccounts: [Address] = [0xf8d6e0586b0a20c7, 0x01cf0e2f2f715450, 0x179b6b1cb6755e31, 0xf3fcd2c1a78f5eee, 0xe03daebed8ca0615]

    for emulator_account in emulatorAccounts {
        // Get the public account
        let account: PublicAccount = getAccount(emulator_account)

        // Find the public Sale reference to their Collection. Fetch it as an optional first to test its existence before attempting to operate on it 
        var accountSalesReference: &ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic}? 
            = account.getCapability<&ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic}>(ExampleMarketplace.SalePublicPath).borrow()

        if (accountSalesReference == nil) {
            log(
                "Unable to find a Sale Collection for account "
                .concat(emulator_account.toString())
            )
        }
        else {
            // There is a Sale Collection stored in a public path. Remove the optional and move on
            let accountSalesReference: &ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic} = accountSalesReference!

            // Log the NFTs that are for sale
            let accountNFTIDs: [UInt64] = accountSalesReference.getIDs()
            var index: Int = 1

            log("Account '".concat(emulator_account.toString()).concat("' NFTs for sale:"))
            
            for nftID in accountNFTIDs {
                log(
                    "NFT #"
                    .concat(index.toString())
                    .concat(":")
                )

                let index: Int = index + 1

                log(
                    "ID: "
                    .concat(nftID.toString())
                    .concat(", Price = ")
                    .concat(accountSalesReference.idPrice(tokenID: nftID)!.toString())
                    .concat("tokens!")
                )
            }
        }
    }
}
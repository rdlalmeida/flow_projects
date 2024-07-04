// import ExampleToken from "../../06/contracts/ExampleToken.cdc"
import ExampleToken from 0xf8d6e0586b0a20c7

// import ExampleNFT from "../../05/contracts/ExampleNFT.cdc"
import ExampleNFT from 0xf8d6e0586b0a20c7

// import ExampleMarketplace from "../contracts/ExampleMarketplace.cdc"
import ExampleMarketplace from 0xf8d6e0586b0a20c7

/*
    This transactions creates a new Sale Collection object, lists an NFT for sale, puts it in account storage,
    and creates a public capability to the sale so that others can buy the token
*/

transaction(priceToSet: UFix64) {
    var receiverCapability: Capability<&ExampleToken.Vault{ExampleToken.Receiver}>
    var collectionCapability: Capability<&ExampleNFT.Collection>

    prepare(account: AuthAccount) {
        /*
            Begin by testing if the expected links for the public and private capabilities already exist. For this I'm going to use the 'check()' sub-function
            after trying to get a capability. If it returns true, the link exists and a capability can be retrieved. In this case, proceed to retrieve the
            capability into a variable. If the check returns a False instead, the link is not yet created. Proceed to do it, while storing the result (the 
            respective capability) to a variable
        */
        if (account.getCapability<&ExampleToken.Vault{ExampleToken.Receiver}>(ExampleToken.VaultPublicPath).check()) {
            // In this case (True) the link already exists. Retrieve a Capability to it
            self.receiverCapability = account.getCapability<&ExampleToken.Vault{ExampleToken.Receiver}>(ExampleToken.VaultPublicPath)
            
            log(
                "Found an existing link at "
                .concat(ExampleToken.VaultPublicPath.toString())
                .concat(". Recovering the Capability...")
            )
        }
        else {
            // Otherwise (False) the link has yet to be created. Do it, retrieving the required Capability
            self.receiverCapability = account.link<&ExampleToken.Vault{ExampleToken.Receiver}>(ExampleToken.VaultPublicPath, target: ExampleToken.VaultStoragePath)
                ?? panic(
                    "Unable to link a ExampleToken.Vault to storage '"
                    .concat(ExampleToken.VaultPublicPath.toString())
                )

            log(
                "The link to "
                .concat(ExampleToken.VaultPublicPath.toString())
                .concat(" does not exist yet. Creating it...")
            )
        }

        // Repeat the process to the Collection Capability
        if (account.getCapability<&ExampleNFT.Collection>(ExampleNFT.CollectionPrivatePath).check()) {
            // Got a true. The link exists. Retrieve the capability from it
            self.collectionCapability = account.getCapability<&ExampleNFT.Collection>(ExampleNFT.CollectionPrivatePath)

            log(
                "Found an existing link at "
                .concat(ExampleNFT.CollectionPrivatePath.toString())
                .concat(". Retrieving the Capability...")
            )
        }
        else {
            // The link is not yet created. Do it and get the capability in the process
            self.collectionCapability = account.link<&ExampleNFT.Collection>(ExampleNFT.CollectionPrivatePath, target: ExampleNFT.CollectionStoragePath)
                ?? panic(
                    "Unable to link a ExampleNFT.Collection to storage '"
                    .concat(ExampleNFT.CollectionPrivatePath.toString())
                )
            
            log(
                "The link to"
                .concat(ExampleNFT.CollectionPrivatePath.toString())
                .concat(" does not exist yet. Creating it...")
            )
        }

        // Get an existing token if using the proper functions
        let collectionReference = self.collectionCapability.borrow() ?? panic("Unable to get a Collection Reference from the collection capability!")
        let nftIdList = collectionReference.getIDs()

        // Retrieve the id for the last NFT in that list
        if (nftIdList.length <= 0) {
            panic("The NFT collection retrieved is still empty")
        }
        else {
            log(
                "Retrieved a NFT collection with "
                .concat(nftIdList.length.toString())
                .concat(" elements in it.")
            )
        }

        // List the token for sale by moving it into the sale object, using the id of the last element in the array returned and the price provided as argument
        let nftIdToSell = nftIdList[nftIdList.length - 1]

        /*
            Before attempting to create a new sale, check storage if a sale resource already exists and recover it if so. Otherwise create a new Sale resource
            from scratch. To do this, attempt to load a saved Sale from storage and check if the returned reference is a nil or not
        */
        var optionalSale: @ExampleMarketplace.SaleCollection? <- account.load<@ExampleMarketplace.SaleCollection>(from: ExampleMarketplace.SaleStoragePath)        

        /*
            VERY IMPORTANT: Apparently Cadence does not does very well with alternative control flows, such as the one imposed by an if-else, namely,
            if I create the same variable (but under different conditions depending on the branch being run) with the same type and name, Cadence still
            does not recognizes this variable when outside of the if-else statement! That's quite limiting... The only way I've found to go around this
            (other than simply destroying any existing Sale at will, which defeats the concept of a Marketplace) is to repeat the same logic in both 
            branches... a lot of repeated code but it works...
        */
        if (optionalSale == nil) {
            // The SaleCollection resource does not exist yet. Procee{ExampleMarketplace.SalePublic}d under this assumption

            // Create a new Sale object intializing it with the reference to the owner's vault
            // let sale: @ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic} <- ExampleMarketplace.createSaleCollection(ownerCollection: self.collectionCapability, ownerVault: self.receiverCapability)
            let sale: @ExampleMarketplace.SaleCollection <- ExampleMarketplace.createSaleCollection(ownerCollection: self.collectionCapability, ownerVault: self.receiverCapability)
            
            // Destroy this optional one, now that we know its a nil
            destroy optionalSale

            // List the new sale
            sale.listForSale(tokenID: nftIdToSell, price: priceToSet)

            // Done. Save the Sale Collection back to storage
            account.save(<- sale, to: ExampleMarketplace.SaleStoragePath)

        }
        else {
            // In this case, there was something stored in storage but it is still an optional at this point. Remove this before moving on
            // let sale: @ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic} <- (optionalSale as @ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic}?)!
            let sale: @ExampleMarketplace.SaleCollection <- optionalSale!

            // Conversion done. List the new NFT sale into this resource
            sale.listForSale(tokenID: nftIdToSell, price: priceToSet)

            // Save the Sale Collection resource back to storage
            account.save(<- sale, to: ExampleMarketplace.SaleStoragePath)
        }

        // Remove any current links to the collections. In this case it does not matter
        account.unlink(ExampleMarketplace.SalePublicPath)

        // Create a public capability to the sale so that others can call its methods. NOTE: This only works because I've ensured that a SaleCollection
        // resource is saved into the storage path used
        let collectionCapability: Capability<&ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic}> = 
            account.link<&ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic}>(ExampleMarketplace.SalePublicPath, target: ExampleMarketplace.SaleStoragePath)!
        
        let collectionRef: &ExampleMarketplace.SaleCollection{ExampleMarketplace.SalePublic} = collectionCapability.borrow()!

        log(
            "Sale created for account "
            .concat(account.address.toString())
            .concat(". Selling NFT #")
            .concat(nftIdToSell.toString())
            .concat(" for ")
            .concat(priceToSet.toString())
            .concat(" tokens!")
        )

        log(
            "Account "
            .concat(account.address.toString())
            .concat(" has the following NFTs for sale: ")
        )

        let NFTsForSale: {UInt64: UFix64} = collectionRef.getNFTs()

        for nft in NFTsForSale.keys {
            log(
                "NFT ID: "
                .concat(nft.toString())
                .concat(", price = ")
                .concat(NFTsForSale[nft]!.toString())
                .concat(" tokens")
            )
        }
    }
}
import ExampleToken from "../../06/contracts/ExampleToken.cdc"
import ExampleNFT from "../../05/contracts/ExampleNFT.cdc"

/*
    This transaction adds an empty Vault to the signer account and mints an NFT with id=1 to be deposited into the 
    NFT collection on the account used in SetupAccount1Transaction.cdc
*/
transaction(recipientAddress: Address) {
    // private reference to this account's minter resource
    let minterRef: &ExampleNFT.NFTMinter
    
    // A random storage path to ensure its emptiness in order to retrieve a 'Never?' resource type
    let bogusPath: StoragePath

    prepare(account: AuthAccount) {
        // Setup a bogus path
        self.bogusPath = /storage/InexistentLocationOnPurpose

        // Create a new vault instance with an initial balance of 30
        let vaultA <- ExampleToken.createEmptyVault()

        // Get the reference of whate
        let referenceType: Type? = account.type(at: ExampleToken.VaultStoragePath)

        // Clean up the storage first before attempting to save anything to that path
        let randomResource <- account.load<@AnyResource>(from: ExampleToken.VaultStoragePath)

        if (randomResource == nil) {
            log(
                "Storage '"
                .concat(ExampleToken.VaultStoragePath.toString())
                .concat("' is still empty...")
                )

            destroy randomResource
            
            // Store the vault in the account storage
            account.save<@ExampleToken.Vault>(<- vaultA, to: ExampleToken.VaultStoragePath)
        }
        else {
            log(
                "Got a '"
                .concat(randomResource.getType().identifier)
                .concat("' resource stored in ")
                .concat(ExampleToken.VaultStoragePath.toString())
                .concat(". Destroying it...")
                )

            // Remove any optionals from the resource retrieved and compare it to the expected type
            let nonOptionalrandomResource <-! randomResource

            // Check if the resource retrieved is from the expected type: ExampleToken.Vault
            if (nonOptionalrandomResource.getType() == vaultA.getType()) {
                // The resource in storage is from the desired type. In this case, destroy the new Vault and save the retrieved resource back to storage
                
            }

            destroy 
        }



        // Create a public Receiver capability to the Vault
        let ReceiverRef = account.link<&ExampleToken.Vault{ExampleToken.Receiver, ExampleToken.Balance}>
            (ExampleToken.VaultPublicPath, target: ExampleToken.VaultPublicPath)

        log("Create a Vault and published a reference")

        // Borrow a reference for the NFTMinter in storage
        self.minterRef = account.borrow<&ExampleNFT.NFTMinter>(from: ExampleNFT.MinterStoragePath) ?? panic("Could not borrow owner's NFT minter reference.")
    }

    execute{
        // get the recipient's public account object
        let recipient = getAccount(recipientAddress)

        /*
            Get the Collection reference for the receiver getting the public capability and borrowing a reference from it
        */
        let receiverRef = recipient.getCapability(ExampleNFT.CollectionPublicPath).borrow<&{ExampleNFT.NFTReceiver}>()
            ?? panic("Could not borrow NFT receiver reference")

        // Mint an NFT and deposit into tge receiver account's collection
        receiverRef.deposit(token: <- self.minterRef.mintNFT())
        
        log("New NFT minted into account ".concat(recipientAddress.toString()))
    }
}
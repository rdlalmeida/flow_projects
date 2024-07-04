import ExampleNFT from "../../05/contracts/ExampleNFT.cdc"
// import ExampleNFT from 0xf8d6e0586b0a20c7

/*
    This transacrion configures a user's account to use the NFT contract by creating a new empty collection,
    storing it in their account storage, and publishing a capability
*/

transaction() {
    prepare(account: AuthAccount) {
        // Create a new empty collection
        let collection: @ExampleNFT.Collection <- ExampleNFT.createEmptyCollection()

        // Cleanup the storage path first
        let randomResource: @AnyResource? <- account.load<@AnyResource>(from: ExampleNFT.CollectionStoragePath)

        if (randomResource == nil) {
            log(
                "There was nothing stored in "
                .concat(ExampleNFT.CollectionStoragePath.toString())
            )
        }
        else {
            log(
                "Got a "
                .concat(randomResource.getType().identifier)
                .concat(" resource in ")
                .concat(ExampleNFT.CollectionStoragePath.toString())
            )
        }

        destroy randomResource

        // Store the empty NFT Collection in account storage
        account.save<@ExampleNFT.Collection>(<- collection, to: ExampleNFT.CollectionStoragePath)

        log("Collection created for account ".concat(account.address.toString()))

        // Create a public capability for the Collection
        account.link<&ExampleNFT.Collection>(ExampleNFT.CollectionPublicPath, target: ExampleNFT.CollectionStoragePath)

        log("Capability created for account ".concat(account.address.toString()))
    }
}
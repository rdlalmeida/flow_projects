import CryptoPoops from "../contracts/CryptoPoops.cdc"
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Start by checking if a Collection already exists in storage. Try to borrow a reference to it and test if it is a nil or not
        var collectionReference = signer.borrow<&CryptoPoops.Collection>(from: CryptoPoops.CollectionStoragePath)

        // Test if the reference is nil and move from this result
        if (collectionReference == nil) {
            // Nothing was found in storage. Create an empty collection and save it to storage.
            let newCollection: @CryptoPoops.Collection <- CryptoPoops.createEmptyCollection() as! @CryptoPoops.Collection

            // Save the new Collection to storage
            signer.save(<- newCollection, to: CryptoPoops.CollectionStoragePath)

            // Inform the user
            log(
                "No collection was found in storage yet for account "
                .concat(signer.address.toString())
                .concat(". Creating and saving one...")
            )
        }
        else {
            // If the code gets here, the assumption is that there is something in storage and that something is the collection I'm looking for. 
            // But right now, that variable is still optional. Force-cast it to the desired type
            collectionReference = collectionReference as! &CryptoPoops.Collection

            // If the code gets here, the last instruction was successful, which implies that the type of the resource is the one I'm looking for
            // Log this to the user and move on
            log(
                "Found a CryptoPoops.Collection resource in account "
                .concat(signer.address.toString())
                .concat(" storage. Nothing else to do")
            )
        }

        // Next one: recreate the public link to the the resource, which at this point I have ensured that it is in storage already
        // Begin by removing any existing links (if there is no link yet, this instruction does nothing. Its safe to use this way I guess)
        signer.unlink(CryptoPoops.CollectionPublicPath)

        // Re-create the link to the public storage
        signer.link<&CryptoPoops.Collection>(CryptoPoops.CollectionPublicPath, target: CryptoPoops.CollectionStoragePath)

        log(
            "Created a public link to"
            .concat(CryptoPoops.CollectionPublicPath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )
    }

    execute {

    }
}
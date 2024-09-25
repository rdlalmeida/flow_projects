import KittyVerse from "../contracts/KittyVerse.cdc"

transaction(recipientAddress: Address, kittyName: String) {
    // Set up the common elements to both phases at this stage: Use the prepare phase to populate them and the execute phase to run code with them.
    let adminReference: &KittyVerse.KittyAdministrator
    let collectionReference: &KittyVerse.KittyCollection{KittyVerse.KittyReceiver}

    prepare(signer: AuthAccount) {
        // Start by retrieving the Administrator reference needed to mint the Kittens
        self.adminReference = signer.borrow<&KittyVerse.KittyAdministrator>(from: KittyVerse.kittyMinterStorage) ??
            panic(
                "Unable to borrow a Reference to a KittyVerse.KittyAdministrator from account "
                .concat(signer.address.toString())
                .concat(". Nothing found in path ")
                .concat(KittyVerse.kittyMinterStorage.toString())
            )

        // Retrieve the capability at this point
        self.collectionReference = getAccount(recipientAddress).getCapability<&KittyVerse.KittyCollection{KittyVerse.KittyReceiver}>(KittyVerse.kittyCollectionPublic).borrow() ??
            panic(
                "Unable to borrow a reference to a KittyVerse.KittyCollection{KittyVerse.KittyReceiver} from account "
                .concat(recipientAddress.toString())
                .concat(". Nothing found in storage path ")
                .concat(KittyVerse.kittyCollectionPublic.toString())
            )
    }

    execute {
        // Create a new Kitty reference
        let newKitty: @KittyVerse.Kitty <- self.adminReference.createKitty(name: kittyName)

        log(
            "Create a new Kitty named '"
            .concat(kittyName)
            .concat("' and with id = ")
            .concat(newKitty.id.toString())
            .concat(". Saving it into ")
            .concat(recipientAddress.toString())
            .concat(" account's...")
        )

        // Save the Kitty to the collection
        self.collectionReference.depositKitten(kitten: <- newKitty)

        log(
            "Kitten saved!"
        )
    }
}
 
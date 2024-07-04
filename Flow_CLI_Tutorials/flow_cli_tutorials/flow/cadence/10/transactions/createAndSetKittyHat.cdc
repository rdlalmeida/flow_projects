import KittyVerse from "../contracts/KittyVerse.cdc"

transaction(recipientAddress: Address, kittyId: UInt64, hatName: String) {
    // The logic on this one follows a similar one taken for the Kitty creation. Check that file for more
    // detailed explanations for what I'm about to do
    let adminReference: &KittyVerse.KittyAdministrator
    let collectionReference: &KittyVerse.KittyCollection{KittyVerse.KittyReceiver}

    prepare(signer: AuthAccount) {
        self.adminReference = signer.borrow<&KittyVerse.KittyAdministrator>(from: KittyVerse.kittyMinterStorage) ??
            panic(
                "Unable to borrow a Reference to a KittyVerse.KittyAdministrator from account "
                .concat(signer.address.toString())
                .concat(". Nothing found in path ")
                .concat(KittyVerse.kittyMinterStorage.toString())
            )

        self.collectionReference = getAccount(recipientAddress).getCapability<&KittyVerse.KittyCollection{KittyVerse.KittyReceiver}>(KittyVerse.kittyCollectionPublic).borrow() ??
            panic(
                "Unable to borrow a reference to a KittyVerse.KittyCollection{KittyVerse.KittyReceiver} from account "
                .concat(recipientAddress.toString())
                .concat(". Nothing found in storage path ")
                .concat(KittyVerse.kittyCollectionPublic.toString())
            )

        // At this point, since both the Administrator and the recipient Collection are proven to exist, move to check if a Kitty with the provided ID exists in the collection
        if (!self.collectionReference.idExists(id: kittyId)) {
            panic(
                "ERROR: Account "
                .concat(recipientAddress.toString())
                .concat(" Collection does not contains a Kitty with ID ")
                .concat(kittyId.toString())
                .concat(" in it.")
            )
        }
    }

    execute {
        // At this point, both the Administrator and Collection exist, and there's a proper Kitty in the last one. Carry on
        // Create the KittyHat to begin with
        let newKittyHat: @KittyVerse.KittyHat <- self.adminReference.createHat(name: hatName)

        // Set the new Hat to the Kitty in the collection. Need a reference to the Kitty in storage
        let kittyReference: &KittyVerse.Kitty = self.collectionReference.getKittyReference(id: kittyId)

        kittyReference.addKittyHat(hat: <- newKittyHat)

        log(
            "Successfully set a new "
            .concat(hatName)
            .concat(" hat on Kitty #")
            .concat(kittyReference.id.toString())
            .concat(", '")
            .concat(kittyReference.kittyName)
            .concat("'")
        )
    }
}
 
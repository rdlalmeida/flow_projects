import KittyVerse from "../contracts/KittyVerse.cdc"

/*
    Simple transactions that prepares an account to receive Kitties and KittyItems
*/
transaction() {
    prepare(signer: AuthAccount) {
        /*
            I can do this in a simple fashion, where I simply overwrite any existing collection in storage and that's it, but the point with
            these exercises is to develop proper professional strategies to go about this. As such, I'm going to take the long road and check
            if a valid KittyCollection is already set in storage.
        */

        // Retrieve whatever is stored in the storage path to a variable. Set it as an optional variable since the storage path can still be empty
        let resourceReference: &AnyResource? = signer.borrow<&AnyResource>(from: KittyVerse.kittyCollectionStorage)

        // And create a proposely null reference (a Never? type)
        let bogusPath: StoragePath = /storage/BogusPublicStoragePath

        // Load and destroy whatever may be in that path (risky, but the chances of retrieving anything from there are slim to none)
        destroy signer.load<@AnyResource>(from: bogusPath)

        // Retrieve a referece to the same storage path, which is now a proper Never? as expected
        let nullReference: &KittyVerse.KittyCollection{KittyVerse.KittyReceiver}? = 
            signer.borrow<&KittyVerse.KittyCollection{KittyVerse.KittyReceiver}>(from: bogusPath)

        /*
        if (nullReference.getType() == Type<Never?>()) {
            log(
                "GOT A VALIID FREAKIN NEVER?"
            )
        }
        */
        
        // Test if the storage path is still empty by comparing whatever was retrieved with a 'Never?', obtained using the Type<>() function
        // NOTE: At this point, since I don't know if I got a proper reference or a reference to a nil (the so called 'Never?'), I cannot get
        // myself rid of the optional, because if the Resource Reference is indeed a 'Never?', for unwrapping it will throw a panic and stop
        // all this
        if (resourceReference.getType() == Type<Never?>()) {
            // Nothing is stored in storage yet. Simplest scenario: create, save and link a new KittyCollection to storage

            // And remove any existing links (there should be none, but nevertheless
            signer.unlink(KittyVerse.kittyCollectionPublic)

            // Create the new collection
            let newKittyCollection: @KittyVerse.KittyCollection{KittyVerse.KittyReceiver} <- KittyVerse.createEmptyKittyCollection()

            // Send it to storage
            signer.save(<- newKittyCollection, to: KittyVerse.kittyCollectionStorage)

            // Create a public link to it too.
            signer.link<&KittyVerse.KittyCollection{KittyVerse.KittyReceiver}>(KittyVerse.kittyCollectionPublic, target: KittyVerse.kittyCollectionStorage)

            log(
                "Account "
                .concat(signer.address.toString())
                .concat(" storage is still empty. Saving a new KittyCollection to ")
                .concat(KittyVerse.kittyCollectionStorage.toString())
            )
        }
        else {
            // In this case, the resource in storage is not a null one, because otherwise the previous if would have been executed. Now I need
            // to check if the type retrieved is from the desired one. Begin by testing if the retrieved type matches the one we want
            // First, normalize the reference to take out the '?'. I can do that safely (without a panic) because I'm sure now that it is not
            // nil (because of the first if)
            let normalizedResourceReferenceType: Type = resourceReference!.getType()

            log(
                "normalizedResourceReferenceType = "
                .concat(normalizedResourceReferenceType.identifier)
            )

            log(
                "Type<&KittyVerse.KittyCollection{KittyVerse.KittyReceiver}>() = "
                .concat(Type<@KittyVerse.KittyCollection>().identifier)
            )

            if (normalizedResourceReferenceType == Type<@KittyVerse.KittyCollection>()) {
                // In this case, there is a resource already stored with the type we want. There should be a link to the public path already,
                // but since I'm at it, rebuild it just in case
                signer.link<&KittyVerse.KittyCollection{KittyVerse.KittyReceiver}>(KittyVerse.kittyCollectionPublic, target: KittyVerse.kittyCollectionStorage)

                log(
                    "Found a valid KittyVerse.KittyCollection{KittyVerse.KittyReceiver} resource in account "
                    .concat(signer.address.toString())
                    .concat(" storage in ")
                    .concat(KittyVerse.kittyCollectionStorage.toString())
                    .concat(" path. Nothing else to do...")
                )
            }
            else {
                // In this case, something else - but not a nil - is stored in that path. Since we really need a proper collection there, start by loading
                // and identifying (as much as possible) the type of the resource in storage

                let randomResource: @AnyResource <- signer.load<@AnyResource>(from: KittyVerse.kittyCollectionStorage)!

                // Log the info before destroying it
                log(
                    "Found a '"
                    .concat(randomResource.getType().identifier)
                    .concat("' type Resource stored under ")
                    .concat(KittyVerse.kittyCollectionStorage.toString())
                    .concat(" path in account ")
                    .concat(signer.address.toString())
                    .concat(". Destroying it...")
                )

                destroy randomResource

                // The rest is easy: create a new KittyCollection, save it to the storage path and redo the link
                let newCollection: @KittyVerse.KittyCollection{KittyVerse.KittyReceiver} <- KittyVerse.createEmptyKittyCollection()

                signer.save<@KittyVerse.KittyCollection{KittyVerse.KittyReceiver}>(<- newCollection, to: KittyVerse.kittyCollectionStorage)

                // Destroy any previous links
                signer.unlink(KittyVerse.kittyCollectionPublic)

                // Create a new one
                signer.link<&KittyVerse.KittyCollection{KittyVerse.KittyReceiver}>(KittyVerse.kittyCollectionPublic, target: KittyVerse.kittyCollectionStorage)

                log(
                    "Saved a new KittyVerse.KittyCollection{KittyVerse.KittyReceiver} into account "
                    .concat(signer.address.toString())
                    .concat(" storage at ")
                    .concat(KittyVerse.kittyCollectionStorage.toString())
                )
            }
        }
    }
    execute {
    }
}
 
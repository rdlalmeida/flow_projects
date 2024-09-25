import HelloWorldResource from "../contracts/HelloWorldResource.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let storage_path: StoragePath = /storage/HelloAssetTutorial

        // Here we create a resource and move it to the variable newHello,
        // then we save it in the account storage

        // First, load, log and destroy anything that can be already stored in that directory
        let leftovers: @AnyResource <- signer.load<@AnyResource>(from: storage_path)

        if (leftovers != nil) {
            log("There was something stored at ".concat(storage_path.toString()).concat(".\n Destroying it..."))
        }
        else {
            log("Storage location at ".concat(storage_path.toString()).concat(" was empty! Continuing..."))
        }

        destroy leftovers

        let newHello <- HelloWorldResource.createHelloAsset()

        signer.save(<- newHello, to: storage_path)
    }

    // In execute, we log a string to confirm that the transaction executed
    execute {
        log("Saved Hello Resource to account.")
    }
}
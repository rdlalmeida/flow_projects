import ExampleToken from "../contracts/ExampleToken.cdc"
// import ExampleToken from "/home/ricardoalmeida/Flow_projects/Flow_CLI_Tutorials/flow_cli_tutorials/flow/cadence/06/contracts/ExampleToken.cdc"
// import ExampleToken from 0xf8d6e0586b0a20c7

// This transaction configures an account to store and receive tokens defined by the ExampleToken contract
transaction(){
    var signerAddress: Address

    prepare(account: AuthAccount) {
        self.signerAddress = account.address

        // Create a new empty Vault object
        let vaultA: @ExampleToken.Vault <- ExampleToken.createEmptyVault()

        // Load, log and destroy any stuff that may be stored at that path in storage.
        let randomResource: @AnyResource? <- account.load<@AnyResource>(from: ExampleToken.VaultStoragePath)

        if (randomResource == nil) {
            log("Storage for account "
            .concat(account.address.toString())
            .concat(" at ")
            .concat(ExampleToken.VaultStoragePath.toString())
            .concat(" is still empty..."))

            // The damn resource is nil but it still needs to be destroyed
            destroy randomResource
        }
        else {
            log("Got a '".concat(randomResource.getType().identifier).concat("' resource type. Destroying it..."))

            destroy randomResource

            log("Done!")
        }

        // Store the vault in the account storage
        account.save<@ExampleToken.Vault>(<- vaultA, to: ExampleToken.VaultStoragePath)

        log("Empty Vault stored")

        // Create a public Receiver capability to the Vault
        let ReceiverRef: Capability<&ExampleToken.Vault{ExampleToken.Provider, ExampleToken.Receiver, ExampleToken.Balance}>? = account.link<&ExampleToken.Vault{ExampleToken.Provider, ExampleToken.Receiver, ExampleToken.Balance}>
            (ExampleToken.VaultPublicPath, target: ExampleToken.VaultStoragePath)

        log("References created!")
    }

    post {
        // Check that the capabilities were created correctly
        getAccount(self.signerAddress).getCapability<&ExampleToken.Vault{ExampleToken.Receiver, ExampleToken.Provider, ExampleToken.Balance}>
            (ExampleToken.VaultPublicPath).check(): "Vault Receiver Reference was not created correctly!"
    }

    execute{

    }
}
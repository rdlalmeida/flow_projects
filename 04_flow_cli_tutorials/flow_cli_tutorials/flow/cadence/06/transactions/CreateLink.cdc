import ExampleToken from "../contracts/ExampleToken.cdc"

/*
    This transaction creates a capability that is linked to the account's token vault.
    The capability is restricted to the fields in the 'Receiver' interface, so it can only
    be used to deposit funds into the account.
*/
transaction(targetAddress: Address) {
    prepare(account: AuthAccount) {
        /*
            Create a link to the Vault in storage that is restriced to the fields and functions in 'Receiver' and 'Balance' interfaces,
            this only exposes the balance field and deposit of the underlying vault.
        */
        account.link<&ExampleToken.Vault{ExampleToken.Receiver, ExampleToken.Provider, ExampleToken.Balance}>
            (ExampleToken.VaultPublicPath, target: ExampleToken.VaultStoragePath)

        log("Public Vault reference created!")
    }

    post {
        /*
            Check that the capabilities were created correctly by getting the public capability and checking
            that it points to a valid 'Vault' object that implements the 'Receiver' interface
        */
        getAccount(targetAddress).getCapability<&ExampleToken.Vault{ExampleToken.Receiver, ExampleToken.Provider, ExampleToken.Balance}>
            (/public/VaultStoragePath).check(): "Vault public reference was not created correctly"
    }
}
 
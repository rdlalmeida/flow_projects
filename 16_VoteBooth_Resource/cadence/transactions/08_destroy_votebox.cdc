/**
    This transaction loads and destroys a VoteBox resource from the transaction signer's storage account.
**/
transaction() {
    prepare(signer: auth(LoadValue, UnpublishCapability) &Account) {
        // TODO
    }

    execute {}
}
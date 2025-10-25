/**
    This transaction deletes every resource from this voting process that it is currently stored in the transaction signer's storage account. This includes all Elections, active and otherwise, BallotPrinterAdmin, ElectionIndex, etc...
**/
transaction() {
    prepare(account: &Account) {}

    execute {}
}
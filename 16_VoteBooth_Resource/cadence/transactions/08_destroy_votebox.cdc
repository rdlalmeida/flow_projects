/**
    This transaction loads and destroys a VoteBox resource from the transaction signer's storage account.
**/
import "VoteBoxStandard"
import "Burner"

transaction() {
    let voteBoxToDestroy: @VoteBoxStandard.VoteBox

    prepare(signer: auth(LoadValue, UnpublishCapability) &Account) {
        // Try to load the VoteBox resource
        self.voteBoxToDestroy <- signer.storage.load<@VoteBoxStandard.VoteBox>(from: VoteBoxStandard.voteBoxStoragePath) ??
        panic(
            "ERROR: Account `signer.address.toString()` does not have a VoteBox stored at `VoteBoxStandard.voteBoxStoragePath.toString()`"
        )
    }

    execute {
        // Done. Destroy it
        Burner.burn(<- self.voteBoxToDestroy)
    }
}
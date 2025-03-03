import "VoteBoothST"

transaction() {
    let authPrinterAdminRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin
    let printerAdminRef: &VoteBoothST.BallotPrinterAdmin
    let signerAddress: Address
    prepare(signer: auth(Storage, Capabilities, VoteBoothST.Admin) &Account) {
        self.signerAddress = signer.address

        // Get an authorized reference
        self.authPrinterAdminRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to get a auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin from path "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        // Get a simple reference
        self.printerAdminRef = signer.capabilities.borrow<&VoteBoothST.BallotPrinterAdmin>(VoteBoothST.ballotPrinterAdminPublicPath) ??
        panic(
            "Unable to get a &VoteBoothST.BallotPrinterAdmin from path "
            .concat(VoteBoothST.ballotPrinterAdminPublicPath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        let authRefOwner: Address? = self.authPrinterAdminRef.getResourceOwner()

        if (authRefOwner == nil) {
            log(
                "The owner of the authorized printer reference is nil!"
            )
        }
        else {
            log(
                "The owner of the authorized printer reference is "
                .concat(authRefOwner!.toString())
            )
        }

        let refOwner: Address? = self.printerAdminRef.getResourceOwner()

        if (refOwner == nil) {
            log(
                "The owner of the normal printer reference is nil!"
            )
        }
        else {
            log(
                "The owner of the normal printer reference is "
                .concat(refOwner!.toString())
            )
        }

        // And load the actual resource to a variable
        let printerAdmin: @VoteBoothST.BallotPrinterAdmin <- signer.storage.load<@VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to get a @VoteBoothST.BallotPrinterAdmin from path "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        let resourceOwner: Address? = printerAdmin.getResourceOwner()

        if (resourceOwner == nil) {
            log(
                "The owner of the printer resource is nil!"
            )
        }
        else {
            log(
                "The owner of the printer resource is "
                .concat(resourceOwner!.toString())
            )
        }

        // All done. Return it back to storage
        signer.storage.save<@VoteBoothST.BallotPrinterAdmin>(<- printerAdmin, to: VoteBoothST.ballotPrinterAdminStoragePath)
    }

    execute {

    }
}
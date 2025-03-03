/*
    NOTE: This transaction is always going to fail, but that's OK. The printer resource is not supposed to be out of storage ever. I designed it to be used through authorized references only. The last version operates on another resource - the OwnerControl - and to be able to mess with both, I cannot have this resource "dangling" without a specific owner, which is what happens when I load this thing. Use this transaction to guarantee that it fails, as it is supposed. 
*/

import "VoteBoothST"


transaction() {
    prepare(signer: auth(Storage) &Account) {
        let storedBallotPrinterAdmin: @VoteBoothST.BallotPrinterAdmin <- signer.storage.load<@VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid VoteBoothST.BallotPrinterAdmin resource from storage "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        let newBallot: @VoteBoothST.Ballot <- storedBallotPrinterAdmin.printBallot(voterAddress: signer.address)

        storedBallotPrinterAdmin.burnBallot(ballotToBurn: <- newBallot)

        signer.storage.save<@VoteBoothST.BallotPrinterAdmin>(<- storedBallotPrinterAdmin, to: VoteBoothST.ballotPrinterAdminStoragePath)
    }

    execute {

    }
}
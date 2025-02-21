import "VoteBoothST"
import "NonFungibleToken"

/*
    This transaction requires no arguments. It starts by loading the VoteBox in the signed account. If one exists, it retrieves the IDs of all Ballots in it. If only one is returned, all is OK so the transaction proceeds to load the Ballot from storage and burn it
*/
transaction() {
    let voteBoxRef: auth(NonFungibleToken.Withdraw) &VoteBoothST.VoteBox
    let signerAddress: Address

    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Start by loading the reference for the VoteBox. Panic if none is found
        self.voteBoxRef = signer.storage.borrow<auth(NonFungibleToken.Withdraw) &VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" from ")
            .concat(signer.address.toString())
        )

        self.signerAddress = signer.address
    }

    execute {
        // Start by checking if the VoteBox has the right number of Ballots (1) to continue
        let ballotIDs: [UInt64] = self.voteBoxRef.getIDs()

        if (ballotIDs.length == 0) {
            log(
                "VoteBox in account "
                .concat(self.signerAddress.toString())
                .concat(" has no Ballots stored yet. Nothing else to do...")
            )

            // Done. Get out of here
            return
        }
        else if (ballotIDs.length > 1) {
            panic(
                "ERROR: Account "
                .concat(self.signerAddress.toString())
                .concat(" has ")
                .concat(ballotIDs.length.toString())
                .concat(" Ballots in it! Multiple Ballots are not allowed in VoteBoxes! Cannot continue")
            )
        }

        // If I got here, I have only one Ballot in storage, as supposed. Extract its ID to a variable
        let ballotID: UInt64 = ballotIDs[ballotIDs.length - 1]

        // Withdraw the Ballot and burn it
        let ballot: @VoteBoothST.Ballot <- self.voteBoxRef.withdraw(withdrawID: ballotID) as! @VoteBoothST.Ballot

        self.voteBoxRef.burnBallot(ballotToBurn: <- ballot)

        log(
            "Successfully withdraw and burned Ballot with ID "
            .concat(ballotID.toString())
            .concat(" from account ")
            .concat(self.signerAddress.toString())
        )
    }
}
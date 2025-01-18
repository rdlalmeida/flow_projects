import "VoteBoothST"
import "NonFungibleToken"

transaction() {
    let voteBoxRef: auth(NonFungibleToken.Withdraw) &VoteBoothST.VoteBox
    let mainAddress: Address

    prepare(signer: auth(Storage) &Account) {
        self.voteBoxRef = signer.storage.borrow<auth(NonFungibleToken.Withdraw) &VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )

        self.mainAddress = signer.address
    }

    execute {
        let ballotIDs: [UInt64] = self.voteBoxRef.getIDs()

        if (ballotIDs.length == 0) {
            panic(
                "VoteBox retrieved from account "
                .concat(self.mainAddress.toString())
                .concat(" has 0 Ballots!")
            )
        }

        let ballotId: UInt64 = ballotIDs[ballotIDs.length - 1]

        let ballot: @VoteBoothST.Ballot <- self.voteBoxRef.withdraw(withdrawID: ballotId) as! @VoteBoothST.Ballot

        self.voteBoxRef.burnBallot(ballotToBurn: <- ballot)

        log(
            "Successfully withdraw and burned Ballot #"
            .concat(ballotId.toString())
            .concat(" from account ")
            .concat(self.mainAddress.toString())
        )
    }
}
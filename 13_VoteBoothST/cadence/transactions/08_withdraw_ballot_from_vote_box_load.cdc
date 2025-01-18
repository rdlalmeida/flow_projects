import "VoteBoothST"
import "NonFungibleToken"

transaction() {
    prepare(signer: auth(Storage) &Account) {
        let voteBox: @VoteBoothST.VoteBox <- signer.storage.load<@VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to retrieve a @VoteBootST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        let ballotIDs: [UInt64] = voteBox.getIDs()

        if (ballotIDs.length == 0) {
            panic(
                "VoteBox retrieved from account "
                .concat(signer.address.toString())
                .concat(" has 0 Ballots!")
            )
        }

        let ballot: @VoteBoothST.Ballot <- voteBox.withdraw(withdrawID: ballotIDs[ballotIDs.length - 1]) as! @VoteBoothST.Ballot

        let burnId: UInt64 = ballot.id

        voteBox.burnBallot(ballotToBurn: <- ballot)

        signer.storage.save<@VoteBoothST.VoteBox>(<- voteBox, to: VoteBoothST.voteBoxStoragePath)

        log(
            "Successfully withdraw and burned Ballot #"
            .concat(burnId.toString())
            .concat(" from a VoteBox in account ")
            .concat(signer.address.toString())
        )
    }

    execute {

    }
}
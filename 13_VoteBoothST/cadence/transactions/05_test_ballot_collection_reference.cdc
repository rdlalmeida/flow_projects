import "VoteBoothST"

transaction() {
    let ballotCollectionRef: &VoteBoothST.BallotCollection

    prepare(signer: auth(Capabilities) &Account) {
        self.ballotCollectionRef = signer.capabilities.borrow<&VoteBoothST.BallotCollection>(VoteBoothST.ballotCollectionPublicPath) ??
        panic(
            "Unable to retrieve a valid &ValidBoothST.BallotCollection reference from "
            .concat(VoteBoothST.ballotCollectionPublicPath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )
    }

    execute {
        log(
            "Ballot Collection reference retrieved from account "
            .concat(VoteBoothST.ballotCollectionPublicPath.toString())
            .concat(" currently contains ")
            .concat(self.ballotCollectionRef.ownedNFTs.length.toString())
            .concat(" Ballots in it ")
        )

        log("Testing the Collection's 'saySomething' function: ")
        log(self.ballotCollectionRef.saySomething())

        // Done with this one.
    }
}
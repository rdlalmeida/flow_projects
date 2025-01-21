import "VoteBoothST"
import "NonFungibleToken"

transaction() {
    let ballotCollectionRef: auth(NonFungibleToken.Withdraw) &VoteBoothST.BallotCollection
    let ballotPrinterRef: auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin
    let signerAddress: Address

    prepare(signer: auth(Capabilities, Storage) &Account) {
        self.ballotCollectionRef = signer.storage.borrow<auth(NonFungibleToken.Withdraw) &VoteBoothST.BallotCollection>(from: VoteBoothST.ballotCollectionStoragePath) ??
        panic(
            "Unable to retrieve a valid &ValidBoothST.BallotCollection reference from "
            .concat(VoteBoothST.ballotCollectionStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )

        self.signerAddress = signer.address

        self.ballotPrinterRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BallotPrinterAdmin>(from: VoteBoothST.ballotPrinterAdminStoragePath) ??
        panic(
            "Unable to retrieve a valid &VoteBoothST.BallotPrinterAdmin at "
            .concat(VoteBoothST.ballotPrinterAdminStoragePath.toString())
            .concat(" from account ")
            .concat(self.signerAddress.toString())
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

        let newBallot: @VoteBoothST.Ballot <- self.ballotPrinterRef.printBallot(voterAddress: self.signerAddress)

        let newBallotId: UInt64 = newBallot.id

        let currentCollectionSize: Int = self.ballotCollectionRef.getLength()

        // Deposit the ballot into the collection
        self.ballotCollectionRef.deposit(token: <- newBallot)

        let newCollectionSize: Int = self.ballotCollectionRef.getLength()

        if (currentCollectionSize + 1 != newCollectionSize) {
            panic(
                "Collection size mismatch detected: Initial collection size: "
                .concat(currentCollectionSize.toString())
                .concat(" Ballots. After depositing one ballot, the collection size is now ")
                .concat(newCollectionSize.toString())
                .concat(" Ballots!")
            )
        }

        let depositedBallot: @VoteBoothST.Ballot <- self.ballotCollectionRef.withdraw(withdrawID: newBallotId) as! @VoteBoothST.Ballot

        let depositedBallotId: UInt64 = depositedBallot.id

        if (newBallotId != depositedBallotId) {
            panic(
                "ERROR: The Ballot id changed! Before deposit, the Ballot had id "
                .concat(newBallotId.toString())
                .concat(". After withdraw from account ")
                .concat(self.signerAddress.toString())
                .concat(", the Ballot has now id ")
                .concat(depositedBallotId.toString())
            )
        }

        // Done with this one. Burn the ballot
        self.ballotPrinterRef.burnBallot(ballotToBurn: <-depositedBallot)

        log(
            "Successfully withdrawn and burned ballot #"
            .concat(depositedBallotId.toString())
            .concat(" from account ")
            .concat(self.signerAddress.toString())
        )
    }
}
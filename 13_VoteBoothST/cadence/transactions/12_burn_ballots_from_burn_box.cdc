import "VoteBoothST"
import "NonFungibleToken"

/*
    This transaction requires no arguments. It simply sets all the Ballots inside the contract deployer BurnBox resource to be destroyed (burned)
*/
transaction() {
    let burnBoxRef: auth(VoteBoothST.Admin) &VoteBoothST.BurnBox
    let signerAddress: Address

    prepare(signer: auth(Storage, Capabilities) &Account) {
        self.signerAddress = signer.address

        self.burnBoxRef = signer.storage.borrow<auth(VoteBoothST.Admin) &VoteBoothST.BurnBox>(from: VoteBoothST.burnBoxStoragePath) ??
        panic(
            "Unable to retrieve an auth(VoteBoothST.Admin) &VoteBoothST.BurnBox at "
            .concat(VoteBoothST.burnBoxStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )
    }

    execute {
        // This one is quite simple. If all the access limitation are covered, this should be as simple as calling the burn function from the reference
        // But in the interest of testing all aspects of this resource, I'm using this opportunity to test all aspects of it
        let currentBallotIdsToBurn: [UInt64] = self.burnBoxRef.getBallotsToBurn()

        let numberOfBallotsToBurn: Int = self.burnBoxRef.howManyBallotsToBurn()

        // These two values need to be consistent
        if (currentBallotIdsToBurn.length != numberOfBallotsToBurn) {
            panic(
                "ERROR: Data inconsistency detected! Account "
                .concat(self.signerAddress.toString())
                .concat(" has a BurnBox with ")
                .concat(currentBallotIdsToBurn.length.toString())
                .concat(" Ballots in it, yet it returns an internal counter of ")
                .concat(numberOfBallotsToBurn.toString())
                .concat(" Ballots! These quantities must be equivalent!")
            )
        }

        // Use the checking function to guarantee that every Id returned is marked for burn in by the corresponding function
        for ballotId in currentBallotIdsToBurn {
            if (!self.burnBoxRef.isBallotToBeBurned(ballotId: ballotId)) {
                panic(
                    "ERROR: Ballot with Id "
                    .concat(ballotId.toString())
                    .concat(" was returned as marked for burning, but the marking function does not recognize it as so!")
                )
            }
        }

        log(
            "Asking the BurnBox to say something and it returns '"
            .concat(self.burnBoxRef.saySomething())
            .concat("'")
        )

        // If the transaction didn't blew up to this point, go ahead and burn the ballots
        self.burnBoxRef.burnAllBallots()

        if (VoteBoothST.printLogs) {
            log(
                "Successfully burned "
                .concat(numberOfBallotsToBurn.toString())
                .concat(" Ballots from account ")
                .concat(self.signerAddress.toString())
                .concat(" Burn Box.")
            )
        }
    }
}
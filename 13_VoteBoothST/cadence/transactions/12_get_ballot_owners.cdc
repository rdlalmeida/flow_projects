import "VoteBoothST"

transaction() {
    prepare(signer: auth(VoteBoothST.Admin) &Account) {
        log(
            "Current ballotOwners: "
        )
        log(
            VoteBoothST.ownerControl.getBallotOwners()
        )
    }

    execute {

    }
}
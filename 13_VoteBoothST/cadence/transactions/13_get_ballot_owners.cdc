import "VoteBoothST"

transaction() {
    prepare(signer: auth(VoteBoothST.BoothAdmin) &Account) {
        log(
            "Current ballotOwners: "
        )
        log(
            ""
        )
    }

    execute {

    }
}
import "VoteBooth"
import "ElectionStandard"

transaction(recipient: Address) {
    prepare(signer: auth(Storage, LoadValue, SaveValue) &Account) {}

    execute {}
}
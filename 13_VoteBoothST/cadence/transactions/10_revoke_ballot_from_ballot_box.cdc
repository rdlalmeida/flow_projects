import "VoteBoothST"
import "NonFungibleToken"

/*
    This transaction is very similar to the one before, but this one tests the Ballot revoke functionality by submitting a Ballot with the default option still set.
*/

transaction() {
    let voteBoxRef: auth(VoteBoothST.VoteEnable) &VoteBoothST.VoteBox
    let ballotBoxRef: &VoteBoothST.BallotBox
    let ownerControlRef: &VoteBoothST.OwnerControl
    let signerAddress: Address
    let voteBoothDeployerAddress: Address
    prepare(signer: auth(Storage) &Account) {
        
    }

    execute {

    }
}
import "VoteBoothST"

transaction(deployerAddress: Address, anotherAddress: Address) {
    let burnBoxRef: &VoteBoothST.BurnBox
    let voteBoxRef: auth(VoteBoothST.VoteBoxWithdraw) &VoteBoothST.VoteBox

    prepare(signer: auth(Storage, VoteBoothST.VoteBoxWithdraw) &Account) {
        let deployerAccount: &Account = getAccount(deployerAddress)
        let anotherAccount: &Account = getAccount(anotherAddress)

        self.burnBoxRef = deployerAccount.capabilities.borrow<&VoteBoothST.BurnBox>(VoteBoothST.burnBoxPublicPath) ??
        panic(
            "Unable to get a valid &VoteBoothSt.BurnBox in "
            .concat(VoteBoothST.burnBoxPublicPath.toString())
            .concat(" for account ")
            .concat(deployerAddress.toString())
        )

        self.voteBoxRef = signer.storage.borrow<auth(VoteBoothST.VoteBoxWithdraw) &VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to get a valid auth(VoteBoothST.VoteBoxWithdraw) &VoteBoothST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
        )
        
    }

    execute {

    }
}
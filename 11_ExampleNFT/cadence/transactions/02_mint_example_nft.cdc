import "NonFungibleToken"
import "ExampleNFTContract"
import "FlowFees"

transaction(recipient: Address) {
    let minter: &ExampleNFTContract.NFTMinter
    let recipientCollectionRef: &{NonFungibleToken.Receiver}

    prepare(signer: auth(BorrowValue) &Account) {
        let currentFeeBalance: UFix64 = FlowFees.getFeeBalance();
        log("Current Fee Balance: ".concat(currentFeeBalance.toString()))

        self.minter = signer.storage.borrow<&ExampleNFTContract.NFTMinter>(from: ExampleNFTContract.MinterStoragePath) ??
        panic(
            "The signer does not store a ExampleNFTContract.NFTMinter object at the path "
            .concat(ExampleNFTContract.CollectionStoragePath.toString())
            .concat("The signer must initialize their account with this collection first!")
        )

        self.recipientCollectionRef = getAccount(recipient).capabilities.borrow<&{NonFungibleToken.Collection}>(ExampleNFTContract.CollectionPublicPath) ??
        panic(
            "Account "
            .concat(recipient.toString())
            .concat(" does not have a NonFungibleToken.Collection Receiver at ")
            .concat(ExampleNFTContract.CollectionPublicPath.toString())
            .concat(". The account must initialize their account with this collection first!")
        )
    }

    execute {
        let mintedNFT: @{NonFungibleToken.NFT} <- self.minter.createNFT()
        self.recipientCollectionRef.deposit(token: <- mintedNFT)

        let currentFeeBalance: UFix64 = FlowFees.getFeeBalance()
        log("Final Fee Balance: ".concat(currentFeeBalance.toString()))
    }
}
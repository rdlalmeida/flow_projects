import "AnotherNFT"

transaction(recipient: Address) {
    let minterRef: &AnotherNFT.NFTMinter
    let collectionCapability: Capability<&AnotherNFT.Collection>
    let collectionRef: &AnotherNFT.Collection

    prepare(signer: auth(BorrowValue) &Account) {
        self.minterRef = signer.storage.borrow<&AnotherNFT.NFTMinter>(from: AnotherNFT.minterStoragePath) ?? 
        panic("Unable to get a NFT Minter reference from account ".concat(signer.address.toString()))

        let recipientAccount: &Account = getAccount(recipient)

        self.collectionCapability = recipientAccount.capabilities.get<&AnotherNFT.Collection>(AnotherNFT.collectionPublicPath)

        log("Capability retrieved: ")
        log(self.collectionCapability)

        self.collectionRef = self.collectionCapability.borrow() ??
        panic("Unable to retrieve a collection resource from account ".concat(recipient.toString()))

        // self.collectionRef = recipientAccount.capabilities.borrow<&AnotherNFT.Collection>(AnotherNFT.collectionPublicPath) ??
        // panic("Unable to retrieve a collection resource from account ".concat(recipient.toString()))
    }

    execute {
        let anotherNFT: @AnotherNFT.NFT <- self.minterRef.createNFT()

        self.collectionRef.deposit(token: <- anotherNFT)

    }
}
import TestNFT from "../contracts/TestNFT.cdc"
import TestAdmin from "../contracts/TestAdmin.cdc"

transaction(recipient: Address) {
    let testCollection: &TestNFT.Collection{TestNFT.CollectionPublic}
    let testAdminMinter: &TestAdmin.TestNFTMinter

    prepare(signer: AuthAccount) {
        self.testCollection = getAccount(recipient).getCapability<&TestNFT.Collection>(TestNFT.collectionPublic).borrow() ??
            panic("Account ".concat(recipient.toString()).concat(" does not have a proper Test Collection set up yet!"))

        self.testAdminMinter = signer.getCapability<&TestAdmin.TestNFTMinter>(TestAdmin.testMinterPrivate).borrow() ??
            panic("Account ".concat(signer.address.toString()).concat(" does not have a proper NFT Minter set up in private storage yet!"))
    }

    execute {
        let testNFT1: @TestNFT.NFT <- self.testAdminMinter.mintTestNFT()
        let testNFT2: @TestNFT.NFT <- self.testAdminMinter.mintTestNFT()
        let testNFT3: @TestNFT.NFT <- self.testAdminMinter.mintTestNFT()

        self.testCollection.deposit(token: <- testNFT1)
        self.testCollection.deposit(token: <- testNFT2)
        self.testCollection.deposit(token: <- testNFT3)

    }
}
import TestNFT from "./TestNFT.cdc"

pub contract TestAdmin {
    pub let testMinterStorage: StoragePath
    pub let testMinterPrivate: PrivatePath

    pub event TestMinterCreated()
    pub event TestNFTCreated()

    pub resource TestNFTMinter {
        pub fun mintTestNFT(): @TestNFT.NFT {
            let testNFT: @TestNFT.NFT <- TestNFT.createTestNFT()
            emit TestNFTCreated()
            return <- testNFT
        }
    }

    init() {
        self.testMinterStorage = /storage/testNFTMinter
        self.testMinterPrivate = /private/testNFTMinter

        let randomMinter: @AnyResource <- self.account.load<@AnyResource>(from: self.testMinterStorage)
        destroy randomMinter
        self.account.unlink(self.testMinterPrivate)

        let minter: @TestNFTMinter <- create TestNFTMinter()
        self.account.save(<- minter, to: self.testMinterStorage)
        self.account.link<&TestNFTMinter>(self.testMinterPrivate, target: self.testMinterStorage)

        emit TestMinterCreated()
    }
}

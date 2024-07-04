import TestNFT from "../contracts/TestNFT.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Same old, same old
        let randomCollection: @AnyResource <- signer.load<@AnyResource>(from: TestNFT.collectionStorage)
        destroy randomCollection
        signer.unlink(TestNFT.collectionPublic)

        let collection: @TestNFT.Collection <- TestNFT.createEmptyCollection()
        signer.save(<- collection, to: TestNFT.collectionStorage)
        signer.link<&TestNFT.Collection>(TestNFT.collectionPublic, target: TestNFT.collectionStorage)
    }

    execute {

    }
}
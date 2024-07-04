import StandardShield from "../contracts/StandardNFTInterface/StandardShield.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let randomCollection: @AnyResource <- signer.load<@AnyResource>(from: StandardShield.collectionStorage)
        destroy randomCollection
        signer.unlink(StandardShield.collectionPublic)

        let collection: @StandardShield.Collection <- StandardShield.createEmptyCollection()
        signer.save(<- collection, to: StandardShield.collectionStorage)
        signer.link<&StandardShield.Collection>(StandardShield.collectionPublic, target: StandardShield.collectionStorage)
    }

    execute {
        
    }
}
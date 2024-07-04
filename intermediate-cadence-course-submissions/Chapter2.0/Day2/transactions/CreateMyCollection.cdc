import MyCollection from "../contracts/MyNewNFTInterface/MyCollection.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        let randomCollection: @AnyResource <- signer.load<@AnyResource>(from: MyCollection.myCollectionStorage)
        destroy randomCollection
        signer.unlink(MyCollection.myCollectionPublic)

        let collection: @MyCollection.Collection <- MyCollection.createEmptyCollection()
        signer.save(<- collection, to: MyCollection.myCollectionStorage)

        signer.link<&MyCollection.Collection>(MyCollection.myCollectionPublic, target: MyCollection.myCollectionStorage)
    }

    execute {

    }
}
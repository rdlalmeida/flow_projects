/* 
    Transaction to create a Collection in a user's account
*/

import Shapes from "../contracts/Shapes.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        if (Shapes.devMode) {
            let oldCollection: @AnyResource <- signer.load<@AnyResource>(from: Shapes.collectionStorage)
            destroy oldCollection

            signer.unlink(Shapes.collectionPublic)
        }

        let shapeCollectionCapability: Capability<&Shapes.Collection> = signer.getCapability<&Shapes.Collection>(Shapes.collectionPublic)

        if (!shapeCollectionCapability.check()) {
            // Create and link a new Collection only if none is present
            let newCollection: @Shapes.Collection <- Shapes.createEmptyCollection()
            signer.save(<- newCollection, to: Shapes.collectionStorage)
            signer.link<&Shapes.Collection>(Shapes.collectionPublic, target: Shapes.collectionStorage)
        }
    }

    execute {

    }
}
 
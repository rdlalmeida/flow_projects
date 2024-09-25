/* 
    Transaction to create a Collection in a user's account
*/

import Shapes from 0xShapes

transaction() {
    prepare(signer: AuthAccount) {
        let shapeCollectionReference: &Shapes.Collection? = signer.borrow<&Shapes.Collection>(from: Shapes.collectionStorage)

        if (shapeCollectionReference == nil) {
            // Create and link a new Collection only if none is present
            let newCollection: @Shapes.Collection <- Shapes.createEmptyCollection()
            signer.save(<- newCollection, to: Shapes.collectionStorage)
            signer.link<&Shapes.Collection>(Shapes.collectionPublic, target: Shapes.collectionStorage)
        }
    }

    execute {

    }
}
 
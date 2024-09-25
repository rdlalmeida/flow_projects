/*
    Transaction that detects if a user has a FLOAT collection set up and if not, creates a new one.
*/

import FLOAT from 0xFLOAT
import Shapes from 0xShapes

transaction() {
    prepare(signer: AuthAccount) {
        // Get the capability first. Just the capability, nothing else
        let floatCollectionCapability: Capability<&FLOAT.Collection> = 
            signer.getCapability<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath)


        // Test the existence of the Collection (actually if it is linked to the Public path). Create and link if if it does not exists yet
        if (!floatCollectionCapability.check()) {
            let floatCollection: @FLOAT.Collection <- FLOAT.createEmptyCollection()
            signer.save(<- floatCollection, to: FLOAT.FLOATCollectionStoragePath)
            signer.link<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath, target: FLOAT.FLOATCollectionStoragePath)
        }
    }

    execute {

    }
}
 
/*
    Transaction that detects if a user has a FLOAT collection set up and if not, creates a new one.
*/

import FLOAT from "../../float/src/cadence/float/FLOAT.cdc"
import Shapes from "../contracts/Shapes.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Get the capability first. Just the capability, nothing else
        let floatCollectionCapability: Capability<&FLOAT.Collection> = 
            signer.getCapability<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath)

        if (Shapes.devMode) {
            let randomCollection: @AnyResource <- signer.load<@AnyResource>(from: FLOAT.FLOATCollectionStoragePath)
            destroy randomCollection

            signer.unlink(FLOAT.FLOATCollectionPublicPath)
        }

        // Test the existence of the Collection (actually if it is linked to the Public path). Create and link if if it does not exists yet
        if (floatCollectionCapability.check()) {
            log("User ".concat(signer.address.toString()).concat(" has a FLOAT Collection set up"))
            log("Nothing to do!")
        }
        else {
            log("User ".concat(signer.address.toString()).concat(" does not has a FLOAT collection set up yet!"))
            log("Creating it...")

            let floatCollection: @FLOAT.Collection <- FLOAT.createEmptyCollection()
            signer.save(<- floatCollection, to: FLOAT.FLOATCollectionStoragePath)
            signer.link<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath, target: FLOAT.FLOATCollectionStoragePath)
            
            log("Done!")
        }
    }

    execute {

    }
}
 
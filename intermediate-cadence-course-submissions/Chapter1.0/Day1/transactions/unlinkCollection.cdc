import Record from "../contracts/Record.cdc"

transaction() {
    prepare(signer: AuthAccount){
        // Check if the public capability is still available
        if (signer.getLinkTarget(Record.CollectionPublicPath) == nil) {
            log("No Capabilities found for ".concat(signer.address.toString()).concat(" at path ").concat(Record.CollectionPublicPath.toString()))
        }
        else {
            signer.unlink(Record.CollectionPublicPath)

            log("Public Capability unlinked for user ".concat(signer.address.toString()).concat(" at path ").concat(Record.CollectionPublicPath.toString()))
        }
    }

    execute {

    }
}
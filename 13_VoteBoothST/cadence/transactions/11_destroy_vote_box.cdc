/*
    This transaction complements the 'create_vote_box.cdc' one. I've written the create one such that it doesn't destroy any VoteBoxes if one is set to created to a storage path that already contains one. To actually destroy one, one has to do it "on purpose" with this transaction
*/

import "VoteBoothST"
import "Burner"

transaction() {
    prepare(signer: auth(Storage, Capabilities) &Account) {
        let oldVoteBox: @VoteBoothST.VoteBox <- signer.storage.load<@VoteBoothST.VoteBox>(from: VoteBoothST.voteBoxStoragePath) ??
        panic(
            "Unable to load a @VoteBoothST.VoteBox at "
            .concat(VoteBoothST.voteBoxStoragePath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
            .concat(". No VoteBoxes found at the location.")
        )

        // Remove any capabilities related to the VoteBox before destroying the resource
        let oldCapability: Capability? = signer.capabilities.unpublish(VoteBoothST.voteBoxPublicPath)

        if (oldCapability != nil) {
            log(
                "Unpublished a Capability of type "
                .concat(oldCapability.getType().identifier)
                .concat(" at ")
                .concat(VoteBoothST.voteBoxPublicPath.toString())
                .concat(" for account ")
                .concat(signer.address.toString())
            )
        }
        // All good. Destroy the resource. Use the Burner contract for it so that the VoteBoothST.VoteBoxDestroyed event is emitted. Turns out that transactions cannot emit custom contract events, although the documentations says otherwise
        // NOTE: If the VoteBox destroyed was not empty, i.e., it has a valid Ballot in it, this one gets burned as well by the burnerCallback function! So, I really need to use the Burner for this case
        Burner.burn(<- oldVoteBox)
    }

    execute {

    }
}
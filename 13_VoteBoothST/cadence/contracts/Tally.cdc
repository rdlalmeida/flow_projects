/*
    This contract is simpler than the VotingBooth ones, but it is equally important. The idea with this is to use a resource, as always, to retrieve previously submitted Ballots into VotingBooth BallotBoxes, anonymize them (if needed because they are pretty anonymous when they get set into the BallotBoxes), counts them and stored the result in an internal resource itself.
*/

import "Burner"
import "VoteBoothST"

// TODO: Can I create a Resource in this contract that can retrieve the Ballots from a VoteBoothST.BallotBox resource that sits in the same account?

access(all) contract Tally {
    // STORAGE PATHS

    // CUSTOM EVENTS

    // CUSTOM ENTITLEMENTS
    access(all) entitlement TallyAdmin

    // CUSTOM VARIABLES

    // CUSTOM RESOURCES
    /*
        This one is the main Resource for this contract. The objective with this one is to use this Resource to retrieve the Ballots, in an anonymized fashion, and then proceed to count them.
    */
    access(all) resource TallyBox {

    }

    init() {
    }
}
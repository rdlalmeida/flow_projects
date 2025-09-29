/**
    ## The Ballot Token standard

    Interface to regulate the access to the base resource for this project, namely, the Ballot.

    @author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "Burner"


access(all) contract interface BallotInterface {
    // CUSTOM ENTITLEMENTS

    // CUSTOM EVENTS

    access(all) resource interface Ballot: Burner.Burnable {
        access(all) let ballotId: UInt64

        access(all)
    }
}
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

        access(all) let electionCapability: Capability

        /**
            This field is used by the Election resource as the key for the internal dictionary where Ballots are stored
            As such, this field needs to be unique and also prevent information leakage to the voter. An obvious choice
            would be the voter's address, since it is a unique element by default, but that raises some privacy issues, since
            there a link somewhere between an address and a Ballot and that's a no no. So, I'm going a level deep and store the
            hash digest of the voter's address in this field and use it as a sort of "private identification string" that is
            also unique, under the assumption that the hash algorithm used is collision resistant to a degree.
            This makes sure that multiple Ballots by the same voter have the same ballotIndex, in principle that is.
        **/
        access(all) let ballotIndex: String
    }
}
/**
    Main contract that takes all the Interfaces defined thus far and sets up the whole resource based process.
    
    This contract establishes all the resources from the interfaces imported but it also has to deal with an interesting limitation of Cadence. Well, it is not a proper technical limitation, but more of a "avoid this if possible" condition, which is having a Collection of Elections, while Elections are also Collections already by themselves. Though there's nothing in Cadence that prevents that, the documentation advises developers to avoid this if possible. And I wanted to because it is going to mess with idea of delegating ElectionPublic capabilities through Ballots. As such, I'm going to use this contract to come up with an automatic way to create and manage Elections without using a Collection.

    @author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/

import "BallotInterface"
import "ElectionInterface"
import "VoteBoxInterface"
import "Burner"
import "Crypto"

access(all) contract VoteBooth {
    // CUSTOM ENTITLEMENTS
    access(all) let voteBoxStoragePath: StoragePath
    access(all) let voteBoxPublicPath: PublicPath

    // CUSTOM EVENTS

    // CUSTOM PATHS
    // access(all) let electionStorage: StoragePath
    // access(all) let electionPublic: PublicPath

    // ---------------------------------------------------------------- BALLOT BEGIN ---------------------------------------------------------------------------
    
    // ---------------------------------------------------------------- BALLOT END -----------------------------------------------------------------------------
    // ---------------------------------------------------------------- ELECTION BEGIN -------------------------------------------------------------------------
    access(all) resource Election: ElectionInterface.Election, ElectionInterface.ElectionPublic, Burner.Burnable {
        access(all) let electionStoragePath: StoragePath
        access(all) let electionPublicPath: PublicPath
        
        access(contract) let electionId: UInt64
        access(contract) let name: String
        access(contract) let ballot: String
        access(contract) let options: {UInt8: String}
        access(contract) let publicKey: String

        access(contract) var storedBallots: @{String: {BallotInterface.Ballot}}
        access(ElectionInterface.ElectionAdmin) var totalBallotsMinted: UInt
        access(ElectionInterface.ElectionAdmin) var totalBallotsSubmitted: UInt

        access(ElectionInterface.ElectionAdmin) var mintedBallots: [UInt64]

        init(
            _electionStoragePath: StoragePath,
            _electionPublicPath: PublicPath,
            _electionName: String,
            _electionBallot: String,
            _electionOptions: {UInt8:String},
            _publicKey: String
            ) {
                self.electionStoragePath = _electionStoragePath
                self.electionPublicPath = _electionPublicPath
                self.electionId = self.uuid
                self.name = _electionName
                self.ballot = _electionBallot
                self.options = _electionOptions
                self.publicKey = _publicKey

                self.storedBallots <- {}
                self.totalBallotsMinted = 0
                self.totalBallotsSubmitted = 0
                self.mintedBallots = []
        }
    }

    // ---------------------------------------------------------------- ELECTION END ---------------------------------------------------------------------------
    // ---------------------------------------------------------------- VOTEBOX BEGIN --------------------------------------------------------------------------
    access(all) resource VoteBox: VoteBoxInterface.VoteBox, Burner.Burnable {
        access(contract) var storedBallots: @{UInt64: {BallotInterface.Ballot}}
        access(contract) var electionsVoted: [UInt64]

        init() {
            self.storedBallots <- {}
            self.electionsVoted = []
        }
    }
    // ---------------------------------------------------------------- VOTEBOX END ----------------------------------------------------------------------------
    // ---------------------------------------------------------------- BALLOTPRINTERADMIN BEGIN ---------------------------------------------------------------
    // TODO: Set the main printer function, one for Ballots, another for Elections (Why not?)
    // TODO: Set an access(all) burnBallot function
    // ---------------------------------------------------------------- BALLOTPRINTERADMIN END -----------------------------------------------------------------
    // ---------------------------------------------------------------- VOTEBOOTH BEGIN ------------------------------------------------------------------------
    init() {
        self.voteBoxStoragePath = /storage/voteBox
        self.voteBoxPublicPath = /public/VoteBox
    }
    // ---------------------------------------------------------------- VOTEBOOTH END --------------------------------------------------------------------------
}
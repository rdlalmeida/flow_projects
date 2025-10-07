/**
    Main contract that takes all the Interfaces defined thus far and sets up the whole resource based process.
    
    This contract establishes all the resources from the interfaces imported but it also has to deal with an interesting limitation of Cadence. Well, it is not a proper technical limitation, but more of a "avoid this if possible" condition, which is having a Collection of Elections, while Elections are also Collections already by themselves. Though there's nothing in Cadence that prevents that, the documentation advises developers to avoid this if possible. And I wanted to because it is going to mess with idea of delegating ElectionPublic capabilities through Ballots. As such, I'm going to use this contract to come up with an automatic way to create and manage Elections without using a Collection.

    @author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/
import "BallotStandard"
import "ElectionStandard"
import "VoteBoxStandard"

access(all) contract VoteBooth {
    // CUSTOM PATHS
    access(all) let voteBoothPrinterAdminStoragePath: StoragePath
    // access(all) let voteBoothPrinterAdminPublicPath: PublicPath

    // CUSTOM ENTITLEMENTS
    access(all) entitlement VoteBoothAdmin

    // CUSTOM EVENTS
    // ---------------------------------------------------------------- BALLOT BEGIN ---------------------------------------------------------------------------
    // ---------------------------------------------------------------- BALLOT END -----------------------------------------------------------------------------

    // ---------------------------------------------------------------- ELECTION BEGIN -------------------------------------------------------------------------
    /**
        I'm using this contract-level dictionary to keep track of all Election resources created since Cadence good practices discourages the use of collections  of collections. Elections are themselves collections of Ballots, therefore I need a way to keep them organised. The strategy is to use this internal dictionary of the format {electionId: {ElectionStoragePath: ElectionPublicPath}} which provides me with all I need to access every Election in storage and their public references.
    **/
    access(self) var electionIndex: {UInt64: {StoragePath: PublicPath}}
    // ---------------------------------------------------------------- ELECTION END ---------------------------------------------------------------------------

    // ---------------------------------------------------------------- VOTEBOX BEGIN --------------------------------------------------------------------------
    // ---------------------------------------------------------------- VOTEBOX END ----------------------------------------------------------------------------

    // ---------------------------------------------------------------- BALLOT PRINTER ADMIN BEGIN -------------------------------------------------------------
    access(all) resource VoteBoothPrinterAdmin {
        /**
            This function is the only process to create new Ballots in this context. I've made the BallotStandard contract such that anyone can import it and use the resource in their own version of this election platform. But for this instance in particular, the only entry point to create a new Ballot is through one of these BallotPrinterAdmin resources.

            @param newLinkedElectionId (UInt64) The electionId to the Election resource that this Ballot can be submitted to.
            @param newElectionCapability (Capability<&{ElectionStandard.ElectionPublic}>) A Capability to retrieve the public reference to the Election associated to this Ballot.
        **/
        access(all) fun createBallot(newLinkedElectionId: UInt64, newElectionCapability: Capability<&{ElectionStandard.ElectionPublic}>, voterAddress: Address): @BallotStandard.Ballot?
        {

            return <- BallotStandard.createBallot(
                newLinkedElectionId: newLinkedElectionId, 
                newElectionCapability: newElectionCapability, 
                newVoterAddress: voterAddress
                )
        }

        access(all) fun createElection(
            newElectionName: String,
            newElectionBallot: String,
            newElectionOptions: {UInt8: String},
            newPublicKey: PublicKey,
            newElectionStoragePath: StoragePath,
            newElectionPublicPath: PublicPath
        ): @ElectionStandard.Election {
            return <- ElectionStandard.createElection(
                newElectionName: newElectionName,
                newElectionBallot: newElectionBallot,
                newElectionOptions: newElectionOptions,
                newPublicKey: newPublicKey,
                newElectionStoragePath: newElectionStoragePath,
                newElectionPublicPath: newElectionPublicPath
            )
        }

        access(all) fun createVoteBox(): @VoteBoxStandard.VoteBox {
            return <- VoteBoxStandard.createVoteBox()
        }
    }
    // ---------------------------------------------------------------- BALLOT PRINTER ADMIN END ---------------------------------------------------------------

    // ---------------------------------------------------------------- VOTEBOOTH BEGIN ------------------------------------------------------------------------
    // VoteBooth Contract constructor
    init() {
        self.voteBoothPrinterAdminStoragePath = /storage/voteBoothPrinterAdmin
        // self.voteBoothPrinterAdminPublicPath = /public/voteBoothPrinterAdmin

        self.electionIndex = {}

        // Clean up the usual storage slot and re-create the BallotPrinterAdmin
        let randomResource: @AnyResource? <- self.account.storage.load<@VoteBoothPrinterAdmin>(from: self.voteBoothPrinterAdminStoragePath)

        destroy randomResource
        
        let newPrinterAdmin: @VoteBoothPrinterAdmin <- create VoteBoothPrinterAdmin()
        self.account.storage.save(<- newPrinterAdmin, to: self.voteBoothPrinterAdminStoragePath)
    }
    // ---------------------------------------------------------------- VOTEBOOTH END --------------------------------------------------------------------------
}
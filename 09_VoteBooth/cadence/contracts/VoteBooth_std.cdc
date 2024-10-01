/*
    This VoteBooth contract version uses the NonFungibleToken standard, which means that I have to implement a whole set of functions and resources that I don't know, at this point, if they are going to help or get in the way (as in, they decrease the security of the system).

    The first task with this contract is making it compatible with the NonFungibleToken standard.
*/
import "NonFungibleToken"

access(all) contract VoteBooth: NonFungibleToken {
    // STORAGE PATHS
    access(contract) let voteMinterStoragePath: StoragePath
    access(all) let voteCollectionStoragePath: StoragePath
    access(all) let voteCollectionPublicPath: PublicPath

    // CUSTOM EVENTS
    access(all) event NonNilTokenReturned(tokenType: Type)

    // CUSTOM VARIABLES
    access(all) let _ballot: String

    /*
        The main element of this system, which in this case is set as a Resource following Flow's NonFungibleToken standard.
    */
    access(all) resource Vote: NonFungibleToken.NFT {
        access(all) let voteId: UInt64

        init() {
            self.voteId = self.uuid
        }
    }

    /*
        The idea with this Resource is it to be used to store the votes from the contract side, i.e., after they were submitted. The idea is for the voters not having these collections (for now at least) since I can use the storage domains as a handy way to guarantee that, at any point, each voter has only one vote in his/her account storage.
    */
    access(all) resource BallotBox: NonFungibleToken.Collection {
        /* 
            This dictionary is going to be used to store the submitted votes. Ideally this structure should have a more suggestive name, but that is impossible if the NonFungibleToken standard is to be followed.
            // TODO: It's getting clearer and clearer that, at some point, I need to create my own standard for this purpose.
        */
        // NonFugibleToken.Collection
        access(contract) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        // I'm going to use this dictionary to store the NFT types supported by the collections in 
        // this contract. This another of those standard requirements
        access(contract) var supportedTypes: {Type: Bool}

        // NonFungibleToken.Receiver
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {

        }

        // NonFungibleToken.Receiver

        // NonFungibleToken.Receiver
        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            // Force-cast the token received to the expected type
            let vote: @VoteBooth.Vote <- token as! @VoteBooth.Vote

            // Save the VoteNFT in the spot determined by its id and save whatever may be in that
            // dicionary entry to a variable. If all goes right, this variable should be 'nil'
            let randomResource: @AnyResource? <- self.ownedNFTs[vote.voteId] <- vote

            // But let's test it anyhow
            if (randomResource != nil) {
                // If something other than a 'nil' was obtained, emit the respective event and move on
                emit NonNilTokenReturned(tokenType: randomResource.getType())
            }

            // Destroy the variable before exiting
            destroy randomResource
        }

        // NonFungibleToken.Collection
        /*
            I can use this function to check out the contents of a VoteNFT. The voter can use it also for verifiability purposes. At some point, the vote contents need to be encrypted and all the verifiability logic seriously revised.
            NOTE: The '_' as function argument means that, when invoked, the argument doesn't need to be preempted, i.e., the function can be called as 'borrowNFT(12)' or 'borrowNFT(id: 12)'
            TODO: Use the 'borrowNFT' function as base to analyse and implement Verifiability.
        */
        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            /*
                Grab a reference to the VoteNFT but not the token itself. This is kinda of a copy of the token parameters but for read-only purposes. The standard implies that I need to return whatever is in the dictionary position, which may be a nil (hence why the return as that '?'). I cannot protect against that at this level so I need to take this into account when requesting this reference.
            */
            let voteRef: &{NonFungibleToken.NFT}? = &self.ownedNFTs[id]

            return voteRef
        }

        // NonFungibleToken.Provider
        /*
            This another of those functions that, ideally should be used only be the vote owner and by the VoteBooth and Tally contracts. These entities need to be the only one able to move a VoteNFT from one account to another.
            TODO: Test the restrictions of this function: only the VoteNFT onwer, the VoteBooth and the Tally contract should be able to use this function and even those uses are restricted to Voter <-> VoteBooth and VoteBooth <-> Tally
        */
        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let vote: @{NonFungibleToken.NFT} <- self.ownedNFTs.remove(key: withdrawID) ?? panic("Unable to retrive a vote with id ".concat(withdrawID.toString()))

            return <- vote
        }

        init() {
            self.ownedNFTs <- {}
        }
    }

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        // TODO:
    }

    /*
        The constructor for the contract (not the NFTs). This one receives a string and sets it has the main ballot, i.e., what this election is all about
    */
    init(ballot: String) {
        self.voteMinterStoragePath = /storage/VoteNFTMinter
        self.voteCollectionStoragePath = /storage/VoteCollection
        self.voteCollectionPublicPath = /public/VoteCollection

        // Set the ballot
        self._ballot = ballot

        // Create and save the one VoteNFTMinter into the contract's own account
        // TODO: This one
    }
}
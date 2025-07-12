/**
    Okey, since I added a whole security layer around minting and burning Ballots, I now have a problem. A small one, but a problem nonetheless: how can a voter burn a Ballot in his/her VoteBox, or from an Election for that matter, without having the Admin access to a BallotPrinterAdmin?
    The solution is to create another resource with deposit only capabilities, sort of a "black box" to where Ballots can only get in but cannot get out. This resource, which I'm calling BurnBox, to keep things consistent. This BurnBox can be accessed by everyone through a public reference, and used to burn Ballots, albeit in a delayed fashion. Ballots deposited in this box have no other "exit" other than getting burned because... I'm writing this thing as such. You gotta love blockchain and smart contracts! No other technology allows me this kind of precise control! Even in the deployer "forgets" to burn the Ballots in this box, there's no way to retrieve a Ballot that was deposited into a BurnBox. Ballots that go inside one either get burned or stay in there forever.
**/

import "Burner"
import "BallotStandard"
import "ElectionStandard"


access(all) contract interface BallotBurner {
    // CUSTOM EVENTS
    // Event for when some other resource other than a BallotStandard.Ballot is retrieved
    access(all) event NonNilResourceReturned(_tokenType: Type)

    // Event to emit whenever a Ballot is sent to the BurnBox to be destroyed at a later stage
    access(all) event BallotSetToBurn(_ballotId: UInt64, _electionId: UInt64, _voterAddress: Address?)

    // Event to signal when a BurnBox is destroyed using the Burner contract
    access(all) event BurnBoxDestroyed(_deployer: Address?)

    access(all) resource interface BurnBox: Burner.Burnable {
        // Save the Ballots to burn in an internal dictionary
        access(contract) var ballotsToBurn: @{UInt64: {BallotStandard.Ballot}}

        /**
            Function to determine if a given Ballot, identified by its ballotId, is set to burn or not. In other words, this function returns a boolean regarding if there's a valid entry in the internal dictionary for the ballotId provided.

            @param: ballotId (UInt64) The main identifier for the Ballot resource whose status needs to be determined.

            @return: Bool If there's a valid entry in the ballotsToBurn dictionary, the function returns true. Otherwise it returns false.
        **/
        access(all) view fun isBallotToBeBurned(ballotId: UInt64): Bool {
            if (self.ballotsToBurn[ballotId] == nil) {
                return false
            }

            return true
        }

        /**
            Function to deposit a Ballot resource into this resource for a future burn. This function simply sets a Ballot received as argument into the internal ballotsToBurn dictionary, emits the respective event and nothing else.

            @param: ballotToBurn (@{BallotStandard.Ballot}) The Ballot resource to be set in the burn dictionary.
        **/
        access(all) fun depositBallotToBurn(ballotToBurn: @{BallotStandard.Ballot}): Void {
            // Save the Ballot's parameter to use them in the event emission later on
            let ballotToBurnBallotId: UInt64 = ballotToBurn.ballotId
            let ballotToBurnElectionId: UInt64 = ballotToBurn.electionId

            // It is possible, but not 100% sure, that the Ballot received was anonymised, which means that its ballotOwner is a nil. Set this parameter as an optional to deal with this possibility
            let ballotToBurnOwner: Address? = ballotToBurn.ballotOwner

            // As usual, Cadence forces me to deal with whatever contents may exist in the self.ballotsToBurn[ballotToBurnId] since it does not guarantees that this slot is a nil. This is part of the process of actually setting a new Ballot to be burned in this resource internal dictionary.
            let randomResource: @AnyResource? <- self.ballotsToBurn[ballotToBurnBallotId] <- ballotToBurn

            // Test the resource to check if a non-nil value was returned somehow
            if (randomResource != nil) {
                // If the code gets here, the randomResource is not a nil. Test if it is a Ballot resource also
                if (randomResource.getType() == Type<@{BallotStandard.Ballot}?>()) {
                    // This is an extreme case in which, somehow, there was a Ballot resource already stored in the same position identified by the ballotId. Panic in this case
                    panic(
                        "ERROR: Found a valid @{BallotStandard.Ballot} already stored with key "
                        .concat(ballotToBurnBallotId.toString())
                        .concat(". Cannot continue!")
                    )
                }

                // If the code gets here, the randomResource is not a Ballot (uff), but it is something else. I have an event just for this case. Emit it but move on. In this case there's no need to stop this process
                emit NonNilResourceReturned(_tokenType: randomResource.getType())
            }

            // If the code gets here, it means that the treatment of the randomResource was finished and no panics were thrown, so all there's left to do is to destroy this randomResource
            destroy randomResource

            // Finish this by emitting the BallotSetToBurn event
            emit BallotSetToBurn(_ballotId: ballotToBurnBallotId, _electionId: ballotToBurnElectionId, _voterAddress: ballotToBurnOwner)
        }

        /**
            Function to get a list of ballotIds of the Ballots that are currently set to be burned.

            @return: [UInt64] Return an array with all the ballotIds of the Ballots currently in storage.
        **/
        // TODO: Validate the entitlement used in this function
        access(BallotStandard.TallyAdmin) view fun getBallotsToBurn(): [UInt64] {
            return self.ballotsToBurn.keys
        }

        /**
            Function to determine how many Ballots are currently set to burn in this resource

            @return: Int The length of the internal ballotsToBurn dictionary
        **/
        access(all) view fun howManyBallotsToBurn(): Int {
            return self.ballotsToBurn.length
        }

        /**
            Function that clears the internal ballotsToBurn dictionary by setting every Ballot currently stored in the BurnBox instance to be burned using the Burner contract.
        **/
        // TODO: Make sure that this entitlement protects the access to this function properly.
        access(BallotStandard.TallyAdmin) fun burnAllBallots(): Void {
            // I need to iterate over the internal Ballot dictionary. Grab the keys into a [UInt64]
            let ballotIdsToBurn: [UInt64] = self.ballotsToBurn.keys

            // Burn each Ballot in a loop
            for ballotId in ballotIdsToBurn {
                let ballotToBurn: @{BallotStandard.Ballot} <- self.ballotsToBurn.remove(key: ballotId) ??
                panic (
                    "Unable to recover a @{BallotStandard.Ballot} from BurnBox.ballotsToBurn for id "
                    .concat(ballotId.toString())
                    .concat(". The dictionary returned a nil!")
                )

                // Before burning the Ballot, retrieve an authorised reference to the Election resource that is associated to this Ballot (if any), and if a valid one was obtained, decrement the number of Ballots minted to that Election resource (I can do this because the decrement function is 'access(account)' protected and this BurnBox and the VotingBooth contract which contains the Election array is all saved in the same account)
                // TODO: THIS


                // Nothing else to do but to burn the Ballot
                Burner.burn(<- ballotToBurn)
            }
        }

        access(contract) fun burnCallback(): Void {
            // Check if I have a valid owner for this Resource (I should, but just in case)
            if (self.owner == nil) {
                // This function is being called from a point where it is not possible to determine the owner of this resource, namely, the address of the account where this BurnBox is stored in
                emit BurnBoxDestroyed(_deployer: nil)
            }

            // Otherwise, I can force cast the self.owner parameter to determine the address of the account where this BurnBox is stored
            emit BurnBoxDestroyed(_deployer: self.owner!.address)
        }

    }
}
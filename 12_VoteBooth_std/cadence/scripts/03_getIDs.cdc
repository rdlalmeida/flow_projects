import "VoteBooth_std"
import "NonFungibleToken"

access(all) fun main(voter: Address): [UInt64] {
    let voterAccount: &Account = getAccount(voter)

    let collectionRef: &{NonFungibleToken.Collection} = voterAccount.capabilities.borrow<&{NonFungibleToken.Collection}>(VoteBooth_std.voteBoxPublicPath) ??
    panic(
        "Unable to retrieve a valid &{NonFungibleToken.Collection} from account ".concat(voter.toString())
    )

    return collectionRef.getIDs()
}

// TODO: THE NFT IS NOT GETTING INTO THE VOTE BOXES!!!! WHERE THE FUCK IS IT THEN???
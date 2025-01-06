import "VoteBoothST"
import "NonFungibleToken"

access(all) fun main(voter: Address): [UInt64] {
    let voterAccount: &Account = getAccount(voter)

    let collectionRef: &{NonFungibleToken.Collection} = voterAccount.capabilities.borrow<&{NonFungibleToken.Collection}>(VoteBoothST.voteBoxPublicPath) ??
    panic(
        "Unable to retrieve a valid &{NonFungibleToken.Collection} from account ".concat(voter.toString())
    )

    return collectionRef.getIDs()
}
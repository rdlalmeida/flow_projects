import "VoteBoothST"

access(all) fun main(): UInt64 {
    return VoteBoothST.getTotalBallotsMinted()
}
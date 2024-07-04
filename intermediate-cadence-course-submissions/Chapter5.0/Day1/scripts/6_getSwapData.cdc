/*
    Script to printout the dictionary in the Swap contract detailing the current addresses in memory and the timestamp associated, if any.
*/
import Swap from "../contracts/Swap.cdc"
// import Swap from 0xb7fb1e0ae6485cf6

pub fun main (): {Address: UFix64} {
    return Swap.userSwaps
}
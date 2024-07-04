import CryptoPoops from "../contracts/CryptoPoops.cdc"

pub fun main(): UInt64 {
    return CryptoPoops.totalSupply
}
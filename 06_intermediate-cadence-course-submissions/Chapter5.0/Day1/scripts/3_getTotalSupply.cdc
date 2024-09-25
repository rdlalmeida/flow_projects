import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"

pub fun main(contractAddress: Address): UFix64 {
    // Lets use a contract borrow for this purpose
    let contractAccount: PublicAccount = getAccount(contractAddress)
    let contractName: String = "RicardoCoin"

    let borrowedContract: &RicardoCoin = contractAccount.contracts.borrow<&RicardoCoin>(name: contractName) ??
        panic("Account ".concat(contractAddress.toString()).concat(" does not has a contract named ").concat(contractName))

    // Done. Return the totalSupply directly from the contract reference
    return borrowedContract.totalSupply
}
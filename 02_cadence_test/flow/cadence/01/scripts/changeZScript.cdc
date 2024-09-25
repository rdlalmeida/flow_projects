import SomeContract from "../contracts/SomeContract.cdc"

pub fun main(newZ: String) {
    SomeContract.testStruct.publicFunc(newZ: newZ)
}
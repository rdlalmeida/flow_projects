// import HelloWorld from 0xf8d6e0586b0a20c7
import HelloWorld from "../contracts/HelloWorld.cdc"

pub fun main() {
    log("Currently, my Number is ")
    log(HelloWorld.myNumber.toString())
}
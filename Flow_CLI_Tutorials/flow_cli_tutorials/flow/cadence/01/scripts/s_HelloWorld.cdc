import HelloWorld from "../contracts/HelloWorld.cdc"

pub fun main(): Void {
    log("About to check HelloWorld's current greeting:\n")
    log(HelloWorld.greeting)
}
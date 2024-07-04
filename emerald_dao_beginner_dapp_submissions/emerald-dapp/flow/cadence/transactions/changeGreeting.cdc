// import HelloWorld from "../contracts/HelloWorld.cdc"
import HelloWorld from 0xb7fb1e0ae6485cf6

transaction(myNewGreeting: String) {
    prepare(signer: AuthAccount) {
    
    }

    execute {
        HelloWorld.changeGreeting(newGreeting: myNewGreeting)
    }
}
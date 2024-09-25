import HelloWorld from "../contracts/HelloWorld.cdc"

transaction(newGreeting: String) {
    prepare(acct: AuthAccount) {}

    execute{
        log("Changing the greeting from ".concat(HelloWorld.greeting).concat(" to ".concat(newGreeting)))

        HelloWorld.changeGreeting(newGreeting: newGreeting)

        log("Done!")

        log("Checking....")

        log(HelloWorld.hello())
    }
}
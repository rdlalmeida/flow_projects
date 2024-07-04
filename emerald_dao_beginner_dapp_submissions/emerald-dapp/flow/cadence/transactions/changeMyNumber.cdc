// import HelloWorld from 0xf8d6e0586b0a20c7
import HelloWorld from "../contracts/HelloWorld.cdc"

transaction(updatedNumber: Int) {
    prepare(account: AuthAccount) {
        log(
            "Changing my number from "
            .concat(HelloWorld.myNumber.toString())
            .concat(" to ")
            .concat(updatedNumber.toString())
        )

        HelloWorld.updateMyNumber(newNumber: updatedNumber)

        log("Done!")
    }

    execute {
    
    }
}
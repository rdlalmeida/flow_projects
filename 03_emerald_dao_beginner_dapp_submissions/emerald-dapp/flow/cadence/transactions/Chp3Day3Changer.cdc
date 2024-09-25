// import Chp3Day3 from "../contracts/Chp3Day3.cdc"
import Chp3Day3 from 0xb7fb1e0ae6485cf6

transaction(myNewState: String, myNewIndex: UInt64) {
    prepare(signer: AuthAccount) {
    
    }

    execute {
        Chp3Day3.changeState(newState: myNewState)
        Chp3Day3.changeIndex(newIndex: myNewIndex)
    }
}
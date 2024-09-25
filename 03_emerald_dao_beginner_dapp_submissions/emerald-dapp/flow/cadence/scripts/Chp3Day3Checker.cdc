// import Chp3Day3 from "../contracts/Chp3Day3.cdc"
import Chp3Day3 from 0xb7fb1e0ae6485cf6

pub fun main(): String {
    return "Current state is "
        .concat(Chp3Day3.state)
        .concat(", current index is ")
        .concat(Chp3Day3.index.toString())
}

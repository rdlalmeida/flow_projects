// import RicardoAlmeida from 0xf8d6e0586b0a20c7
import RicardoAlmeida from "../contracts/RicardoAlmeida.cdc"

pub fun main() {
    log(
        "Currently, Ricardo is "
        .concat(RicardoAlmeida.is)
    )
}

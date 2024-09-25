import IPizza from "../contracts/IPizza.cdc"
pub fun main(): Void {
    // Import the emulator account
    let account: PublicAccount = getAccount(0xf8d6e0586b0a20c7)
    let contractName: String = "Pizza"

    let borrowedPizza: &IPizza = account.contracts.borrow<&IPizza>(name: contractName) ??
        panic("Unable to borrow ".concat(contractName).concat(" contract"))

    log(
        "Contract "
        .concat(contractName)
        .concat(" has size ")
        .concat(borrowedPizza.getSize().toString())
        .concat(" and is filled with: ")
        )
    
    for topping in borrowedPizza.getToppings() {
        log(topping)
    }
}
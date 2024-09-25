import IPizza from "../contracts/IPizza.cdc"

transaction(newTopping: String){

    let borrowedContract: &IPizza
    prepare(signer: AuthAccount) {
        // I already have the account in the signer parameter. Borrow the contract
        let contractName: String = "Pizza"
        self.borrowedContract = signer.contracts.borrow<&IPizza>(name: contractName) ??
            panic("Cannot borrow ".concat(contractName).concat(" contract!"))
    }

    execute {
        self.borrowedContract.addTopping(ingredient: newTopping)
    }
}
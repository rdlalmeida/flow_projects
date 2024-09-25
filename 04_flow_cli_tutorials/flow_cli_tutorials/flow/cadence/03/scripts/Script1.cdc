import HelloWorldResource2 from "../contracts/HelloWorldResource2.cdc"

pub fun main(mainAddress: Address) {
    /*
        Cadence code can get an account's public account object by using the getAccount() built-in function
    */
    log("Getting account from ".concat(mainAddress.toString()))

    let helloAccount = getAccount(mainAddress)

    /*
        Get the public capability from the public path of the owner's account
    */
    log("Getting Capability from ".concat(helloAccount.address.toString()))
    let helloCapability = helloAccount.getCapability<&HelloWorldResource2.HelloAsset>(HelloWorldResource2.publicLocation)

    /*
        Borrow a reference for the capability
    */

    let helloReference = helloCapability.borrow() ?? panic("Could not borrow a reference to the hello capability")

    /*
        The log built-in function logs its argument to stdout

        Here we are using optional chaining to call the "hello" method on the HelloAsset resource that is referenced
        in the published area of the account.
    */
    log(helloReference.hello())
}
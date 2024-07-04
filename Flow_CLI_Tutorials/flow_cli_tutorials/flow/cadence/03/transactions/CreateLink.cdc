import HelloWorldResource2 from "../contracts/HelloWorldResource2.cdc"

/*  This transaction creates a new capability for the HelloAsset resource in storage 
    and adds it to the account's public area.

    Other accounts and scripts can use this capability to create a reference to the
    private object to be able to access this fields and call its methods
*/
transaction {
    prepare(account: AuthAccount) {
        //let randomResource: @HelloWorldResource2.HelloAsset <- account.load<@HelloWorldResource2.HelloAsset>(from: storageLocation) 
        //?? panic("Something else other than a HelloWorldResource2.HelloAsset was stored in ".concat(storageLocation.toString()))

        // destroy randomResource

        account.save(<- HelloWorldResource2.createHelloAsset(), to: HelloWorldResource2.storageLocation)

        /*
            Create a public capability by linking the capability to a 'target' object in account storage.
            The capability allows access to tyhe object through an interface defined by the owner.
            This does not check if the link is valid or if the target exists.
            It just creates the capability.
            The capability is created and stored at /public/Hello, and is also returned from the function.
        */
        account.link<&HelloWorldResource2.HelloAsset>(HelloWorldResource2.publicLocation, target: HelloWorldResource2.storageLocation)

        let capability: Capability<&HelloWorldResource2.HelloAsset> = account.getCapability<&HelloWorldResource2.HelloAsset>(HelloWorldResource2.publicLocation)
        /*
            Use the capability's borrow method to create a new reference to the object that the capability links to.
            We use optional chaining "??" to get the value because result of the borrow could fail, so it is an optinal.
            If the optional is nil, the panic will happen with a descriptive error message
        */

        let helloReference = capability.borrow() ?? panic("Could not borrow a reference to the hello capability")

        // Call the hello function using the reference to the HelloAsset resource
        log(helloReference.hello())
    }
}
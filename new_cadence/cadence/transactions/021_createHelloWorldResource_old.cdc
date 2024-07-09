// Imports in Cadence are relative. But they also work as
// import HelloWorldResource from "../contracts/HelloWorldResource.cdc" 

import "HelloWorldResource"

// TODO: Can I instantiate the contract and create a Resource WITHOUT using the dedicated function? Check it.

transaction() {
    // Good programming practices suggest defining non-initialized transaction-wide variables. These
    // variables are accessible in both the prepare and execute phases.
    // I have this one to store the address of the account that runs this transaction, i.e., the 
    // transaction signer
    let accountAddress: Address
    // Another one for the storage path, but it is mostly because I want to print something 
    // informative in the execute phase.
    let storageLocation: StoragePath

    /*
        The prepare phase is the where the transaction has access to the Authorization Account, i.e., an abstraction of the account that signed this transaction (an object of type 'AuthAccount'). This step used to be quite sensible and made transactions problematic because of oversized control over the signer account, which could be used to transfer assets to a malicious actor for example. The Crescendo upgrade adds new layers of security by, for example, limiting the prepare phase to certain actions, such as 'SaveValue', which limits the transaction to solely save objects into the signing account, thus preventing unwanted transfers or deletions of stored digital objects.

        NOTE: The flow-cli is still using the 'old' interpreter and doesn't want anything with the new signature for accessing an AuthAccount in the prepare phase:
            
            prepare(signer: auth(SaveValue) &Account)

        This new signature allows for more secure transactions due to the increased granularity of access controls, namely the auth(SaveValue) which limits this transaction to save stuff into the signer's account and nothing else. This makes transaction analysis way more simpler since we don't need (in principle) to check every line. I can be sure, by this entitlement alone, that this transaction is not going to empty the user storage for example (can we be 100% sure with these entitlements alone?)
    */
    prepare(signer: AuthAccount) {

        // The transaction-wide parameters should be set at the head of the prepare phase
        self.accountAddress = signer.address
        self.storageLocation = /storage/HelloAssetDemo

        /*
            Create the Resource by accessing the contract abstraction (HelloWorldResource) and invoking the minter function (createHelloAsset())
            After creation, the Resource currently "lives" inside the transaction context, specifically in the newHello variable. Since this variable holds a resource, it was defined as @HelloWorldResource.HelloAsset. This notation is optional but advisable since it clarifies wich type of object is stored in the variable.

            '@HelloWorldResource.HelloAsset' means 
                '@' - A Resource, 
                'HelloWorldResource' - The Smart Contract that implements the Resource, 
                '.HelloAsset' - The type of the Resource
            
            The variable newHello references a Resource of type 'HelloAsset' that is implemented by a Smart Contract named 'HelloWorldResource'

        */
        let newHello: @HelloWorldResource.HelloAsset <- HelloWorldResource.createHelloAsset()

        /*
            After being created, the Resource cannot exist in the "ether". It must be moved to somewhere permanent or destroyed. In this case, the Resource is saved into the signer's account main storage and into a specific 'box' in that storage area named 'HelloAssetDemo'
            Resources cannot simply be sent to storage 'at will'. They need to be indexed in storage somehow, i.e., the actual spot in which they are stored needs to be defined and, as it should be obvious, needs to be unique for that account and storage location.
        */
        signer.save(<- newHello, to: self.storageLocation)
    }

    execute{
        log(
            "HelloAsset created by account 0x".concat(
                self.accountAddress.toString()).concat(
                    " to storage path ".concat(
                        self.storageLocation.toString()
                    )
                )
            )
    }
}
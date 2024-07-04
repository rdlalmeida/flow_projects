Q1. Explain the two most common mistakes Cadence developers make regarding poor capability links.

Careless and inexperienced Cadence developers tend to either mess up the importing of interfaces when defining Capability links, mainly by missing relevant interfaces in the imported set, or even setting some that shouldn't be set, such as the infamous NonFungibleToken.Provider interface when linking a Collection to public storage and thus allowing for the withdrawal of NFTs from third parties without user control (surely that must have happened in some Flow project somewhere)
Another common mistake is the omission of the base resource type when linking it, which defaults to a &AnyResource instead. This widens the scope of resources that can be borrowed from the public link, which can lead to a world of problems that a savvy and dishonest Cadence developer can exploit.

Q2. Rewrite this script from the NBATopShot official repo to link users' collections properly.

Revised the script, under my own code writing standards:
```cadence
transaction() {
    prepare(acct: AuthAccount) {
        // Check if the collection exists first
        if (acct.borrow<&TopShot.Collection>(from: /storage/MomentCollection) == nil) {
            // create the collection
            let collection: @TopShot.Collection <- TopShot.createEmptyCollection() as! @TopShot.Collection

            // Save the collection to storage
            acct.save(<- collection, to: /storage/MomentCollection)

            // Create a public link
            acct.link<&TopShot.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, TopShot.MomentCollectionPublic, MetadataViews.ResolverCollection}>(/public/MomentCollection, target: /storage/MomentCollection)
        }
    }

    execute {

    }
}
```

Q3. What do you think the transaction looked like to set up this user's collection?

The transaction that created and linked the Collection would be something like this:

```cadence
import ExampleNFT from "../../../../common_resources/contracts/ExampleNFT.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Create the collection resource. This is where the scripts in question may fail or not: the setup of the main resource (and the link operation later on)
        // NOTE: Since the createEmptyCollection function returns a NonFungibleToken.Collection, the resulting resource needs to be downcasted to the proper type
        let collection: @ExampleNFT.Collection{ExampleNFT.CollectionPublic} <- ExampleNFT.createEmptyCollection() as! @ExampleNFT.Collection

        // Save it and link it
        signer.save(<- collection, to: /storage/Collection)
        signer.link<&ExampleNFT.Collection{ExampleNFT.CollectionPublic}>(/public/Collection, target: /storage/Collection)
    }

    execute {

    }
}
```

Lets check it out:

Create a new Collection with the transaction above from the emulator account(0xf8d6e0586b0a20c7):
![image](https://user-images.githubusercontent.com/39467168/213733989-704ae375-35c2-439f-82d2-f01dcb6e33bc.png)

Running the first script, it fails:

![image](https://user-images.githubusercontent.com/39467168/213733606-c7825c37-2546-41b8-8ee9-dd8ad730167e.png)

But the other one works:

![image](https://user-images.githubusercontent.com/39467168/213733718-1c1a2cc9-3bb3-4e6e-8712-9b7e98ede49d.png)

Q4. What do you think the transaction looked like to set up this user's collection?

In this case, it seems that the transaction that created the Collection omitted the main type of the Resource:

```cadence
import ExampleNFT from "../../../../common_resources/contracts/ExampleNFT.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Create a collection but do so without defining a specific type but specifying the interface that it must conform to
        // FUN FACT: If the type of the Collection is not specified, Cadence doesn't bother you about casting the output from the createEmptyCollection(). But if you do
        // and the return and expected types don't match, Cadence tells you about it and forces the downcast
        let collection: @AnyResource{NonFungibleToken.CollectionPublic} <- ExampleNFT.createEmptyCollection()

        // Save and link the Collection as before
        signer.save(<- collection, to: /storage/badTypeCollection)
        signer.link<&AnyResource{NonFungibleToken.CollectionPublic}>(/public/badTypeCollection, target: /storage/badTypeCollection)
    }

    execute {

    }
}
```

Lets see if it works:

Create the collection:
![image](https://user-images.githubusercontent.com/39467168/213746450-ac3390c7-ada3-4728-997e-d1867298699f.png)

Running the first script, it fails as predicted since it expects a @ExampleNFT.Collection and gets a @AnyResource instead, which essentially loads a nil into the variable:

![image](https://user-images.githubusercontent.com/39467168/213746727-9d5655e7-ea41-40d2-958f-4a69d8866c66.png)

Running the second script that specifies the type to retrieve as @AnyResource, as well as the interface, it works:

![image](https://user-images.githubusercontent.com/39467168/213747612-8cfee5bb-3b48-4617-ae8c-133c4a1fce0c.png)

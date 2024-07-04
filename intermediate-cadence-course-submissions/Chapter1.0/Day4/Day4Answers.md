Q1. Explain what a resource identifier is.

A Resource identifier is String composed by the concatenation between account address where the contract that contains that Resource definition is deployed, the contract name and Resource Type name. These elements are prefixed by an 'A' and separated with a '.'. This element is able to uniquely identify every Resource type in the Flow environment (the inclusion of the contract address makes it so)


Q2. Is it possible for two different resources, that have the same type, to have the same identifier?

Yes, if constructed from the same contract, which also implies being deployed in the same account. For example, if I have a contract that defines a Resource such as:

```cadence
pub contract ResourceTypes {
    pub resource ExampleResource {
        pub let name: String

        init(name: String) {
            self.name = name
        }
    }

    pub fun createExampleResource(name: String): @ExampleResource {
        return <- create ExampleResource(name: name)
    }
}
```

And then deploy it to the emulator admin account (0xf8d6e0586b0a20c7). If I then create two different Resources and log their identifiers:
```cadence
import ResourceTypes from "../contracts/ResourceTypes.cdc"

transaction(name1: String, name2: String) {
    prepare(signer: AuthAccount) {
        // Create two different resources from the same contract but with the same type 
        let resource01: @ResourceTypes.ExampleResource <- ResourceTypes.createExampleResource(name: name1)

        let resource02: @ResourceTypes.ExampleResource <- ResourceTypes.createExampleResource(name: name2)

        // Lets check their types then

        log("Resource 01 (name = ".concat(resource01.name).concat(") identifier: ".concat(resource01.getType().identifier)))
        log("Resource 02 (name = ".concat(resource02.name).concat(") identifier: ".concat(resource02.getType().identifier)))

        destroy resource01
        destroy resource02
    }

    execute {

    }
}
```
It returns:

![image](https://user-images.githubusercontent.com/39467168/214044424-f6080479-8204-473b-9f1f-45974ca1e578.png)

The 2 Resources have different names but their types are identical.

Q3. Is it possible for two different resources, that have a different type, to have the same identifier?

No, by the same reason above. If the types are different then the last element of the identifier String is different too, and so is the identifier itself since it is composed from them.

Q4. Based on the included comments:
- What is wrong with the following script? 

The borrow function is not specifying a Type, therefore is "asking" for an &AnyResource by default, as long as it abides from the NonFungibleToken.CollectionPublic. This lack of narrowing regarding the returning type can be very dangerous.

- Explain in detail how someone hack this script to always return `true`. 

The script itself doesn't need to be hacked per se, but a dishonest actor can save and link publicly a Resource that abides by the NonFungibleToken.CollectionPublic without necessarily establishing NFTs of the expected type. As such, this user can easily set up a Minter resource and mint NFTs of the bogus type at will.
Or even simpler, the NonFungibleToken.CollectionPublic only requires that the underlying Resource contains a getIDs() function that returns an array of UInt64. A lazy dishonest user can simply set that function in that resource as:

```cadence
pub fun getIDs(): [UInt64] {
    return [1, 2, 3, 4, 5, 6, 7, 8]
}
```

And that will make that script return <code>true</code> every time.

- Then, what are two ways we could fix this script to make sure it is safe?

    - The obvious one is to simply make sure that correct Type is returned by specifying properly in the script (assuming that the script expects a TopShot.Collection):

    ```cadence
    import NonFungibleToken from 0x02
    import TopShot from 0x01

    pub fun main(user: Address): Bool {
        // In this case the borrow() function specifies that a TopShot.Collection{NonFungibleToken.CollectionPublic} needs to be returned to continue 
        let collection: &TopShot.Collection{NonFungibleToken.CollectionPublic} =
            getAccount(user).getCapability(/public/Collection)
                .borrow<&TopShot.Collection{NonFungibleToken.CollectionPublic}>()
                ?? panic("Your TopShot Vault is not setup correctly.")

        if (collection.getIDs().length > 5) {
            return true
        }

        return false
    }
    ```

    If a user attempts to run this script on a non-TopShot.Collection resource, it simply panics and prevents any further mischief.

    - Alternatively we can change the script to make sure that the collection resource returned is of the required type and prevent the code from moving forward if that happens not to be the case:

    ```cadence
    import NonFungibleToken from 0x02

    // For this case we can even omit the import of the original contract. The type comparison is going to happen between Strings
    // import TopShot from 0x01

    pub fun main(user: Address): Bool {
        // In this case we revert the collection type to an &AnyResource{NonFungibleToken.CollectionPublic}
        let collection: &{NonFungibleToken.CollectionPublic} =
            getAccount(user).getCapability(/public/Collection)
                .borrow<&{NonFungibleToken.CollectionPublic}>()
                ?? panic("Your TopShot Vault is not setup correctly.")

        // But lets do an assert at this point before doing anything else further
        assert(
            collection.getType().identifier == "A.01.TopShot.Collection", message: "This collection does not have the expected type! Cannot continue"
        )

        if (collection.getIDs().length > 5) {
            return true
        }

        return false
    }
    ```

    Any attempt to run this script on a non-TopShot.Collection Resource is going to trigger that assert and stop the code.


Q5. Rewrite this script such that we verify we are reading a balance from a FlowToken Vault.

Fixed script:

```cadence
import FungibleToken from 0xf233dcee88fe0abe


pub fun main(user: Address): UFix64 {
    // As it is indicated, I need to retrieve the Vault as &AnyResource because of a bad public link
    let vault = getAccount(user).getCapability(/public/Vault)
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Your Vault is not set up correctly")

    // I got something back. Make sure its the correct type with an assert. First, I need to "build" the String to compare using a bit of code gymnastics
    // First, get the user's short address, i.e., without the '0x' prefix
    let userShortAddress: String = user.toString().slice(from: 2, upTo: user.toString().length)

    // Compose the type to compare
    let expectedType: String = "A.".concat(userShortAddress).concat(".FungibleToken.Vault")

    // Finally assert the thing
    assert(
        vault.getType().identifier == expectedType, message: "The resource borrowed does not have the expected type: Expected '"
            .concat(expectedType).concat("', got a '").concat(vault.getType().identifier).concat("' instead")
    )

    return vault.balance
}
```
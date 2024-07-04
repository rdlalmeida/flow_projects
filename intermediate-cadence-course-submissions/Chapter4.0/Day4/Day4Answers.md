1. Assuming the user's collection is set up properly, what will be returned from this function?

```cadence
import ExampleNFT from 0x01
import NonFungibleToken from 0x02

pub fun main(): [UInt64]? {
  let token: @ExampleNFT.NFT <- create NFT()
  if let collection = getAccount(0x01).getCapability(/public/Collection).borrow<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>() {
    return collection.getIDs()
  }
  return nil
}
```

* If all is correct in storage and properly linked to the public storage, this script should return a `[UInt64]`, i.e., the if condition evaluates to non-nil, the collection variable is properly set and the ID array is returned.

2. Assuming the user's collection was **not** set up properly, what will be returned from this function?

```cadence
import ExampleNFT from 0x01
import NonFungibleToken from 0x02

pub fun main(): [UInt64]? {
  let token: @ExampleNFT.NFT <- create NFT()
  if let collection = getAccount(0x01).getCapability(/public/Collection).borrow<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>() {
    return collection.getIDs()
  } else {
    return []
  }
  return nil
}
```

* In this case, the `if` statement evaluates to `nil`, which in this context is functionally equivalent to `false`. But in that case, the `else` branch executes instead and a `[]` is returned.

3. Assuming the user's collection was **not** set up properly, what will be returned from this function?

```cadence
import ExampleNFT from 0x01
import NonFungibleToken from 0x02

pub fun main(): [UInt64]? {
  let token: @ExampleNFT.NFT <- create NFT()
  if let collection = getAccount(0x01).getCapability(/public/Collection).borrow<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>() {
    return collection.getIDs()
  }
  return nil
}
```

* Same as before - the `if` evaluates to `nil`, i.e., `false` - but since there's no `else` in this case, the `if` is bypassed and the final `nil` is returned instead.

4. What are the two outcomes that could happen when I run this script? Explain each.

```cadence
import ExampleNFT from 0x01
import NonFungibleToken from 0x02

pub fun main(user: Address): [UInt64] {
  let collection = getAccount(user).getCapability(/public/Collection).borrow<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>()

  return collection!.getIDs()
}
```

* It depends if a `ExampleNFT.Collection{NonFungibleToken.CollectionPubic}` was correctly created and linked to the `/public/Collection` path. If that was the case,
the collection variable has a proper Collection in it, the `!` gets rid of the optional, the `getIDs()` runs OK and a `[UInt64]` is returned.
If not, the borrow fails and the collection variable is set to a `nil`. In this case, trying to unwrap it before running the `getIDs()` function is going to raise a panic and abort the script.

5. What is wrong with the below script? 
- a) Please fix it (you are not allowed to modify this line: `return collection?.getIDs()`).
- b) After you fix it, what are the two possible outcomes that could happen when you run the script? Explain each.

```cadence
import ExampleNFT from 0x01
import NonFungibleToken from 0x02

pub fun main(user: Address): [UInt64] {
  let collection = getAccount(user).getCapability(/public/Collection).borrow<&ExampleNFT.Collection{NonFungibleToken.CollectionPublic}>()

  return collection?.getIDs()
}
```

* a) The return type of the script is wrong. The signature should be:
    ```cadence
        pub fun main(user: Address): [UInt64]?
    ```
    because, with that return statement, this script can return either a `[UInt64]` or a `nil`, hence the optional.

* b) As indicated above, the optional chaining operator in the return statement is going to suppress the panic in the case of non properly set ExampleNFT.Collection. Instead, if a correct `ExampleNFT.Collection` is obtained in `collection`, the `getIDs()` runs OK and a `[UInt64]` is returned. Otherwise, if the borrow fails, `collection` resolves to `nil`.

6. Write the below code in `if-else` format instead.

```cadence
let vault = getAccount(user).getCapability(/public/Vault).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!
var status = vault.balance >= 10000 ? "Flow Legend" : vault.balance < 10 ? "Needs More" : vault.balance > 5000 ? "Flow Believer" : "Unknown"
```

```cadence
let vault: &FlowToken.Vault{FungibleToken.Receiver} = getAccount(user).getCapability(/public/Vault).borrow<&FlowToken.Vault{FungibleToken.Receiver}>()!

var status: String = ""

if (vault.balance >= 10000) {
    status = "Flow Legend"
}
else {
    if (vault.balance < 10) {
        status = "Needs More"
    }
    else {
        if (vault.balance > 5000) {
            status = "Flow Believer"
        }
        else {
            status = "Unknown"
        }
    }
}
```

7. Explain a potential benefit of using conditional chaining as opposed to force unwrapping an optional.

The biggest advantage is the suppression of the panic if the variable in question ends up evaluating to a nil. We can then prepare the code to deal with that option in a way where it doesn't force the function to abort and revert whatever has happened up to that point. If getting a `nil` into some variable is not critical, i.e., is something that allows the process to complete in some other capacity, this is the way to go.
1. Using the FLOAT contract, write a properly structured transaction on Mainnet that transfers a FLOAT with a specific id to a recipient.

* transferFLOAT.cdc

```cadence
import FLOAT from 0x2d4c3caffbeab845
import NonFungibleToken from 0x1d7e57aa55817448

transaction(floatId: UInt64, recipient: Address) {
    // Local variables
    // The recipient's Collection Reference
    let recipientCollection: &FLOAT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, FLOAT.CollectionPublic}

    // The provider's Collection Reference
    let providerCollection: &FLOAT.Collection

    prepare(signer: AuthAccount) {
        // Get all the references to the local variables
        // Get a reference to the recipient Collection via Capability
        self.recipientCollection = 
            getAccount(recipient).getCapability<&FLOAT.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, FLOAT.CollectionPublic}>(FLOAT.FLOATCollectionPublicPath).borrow() ??
                panic("Account ".concat(recipient.toString()).concat(" does not have a proper FLOAT Collection setup yet"))

        // Borrow a reference to the provider collection (without the Public Capability because we need to access the Withdraw function)
        self.providerCollection = signer.borrow<&FLOAT.Collection>(from: FLOAT.FLOATCollectionStoragePath) ??
            panic("Account ".concat(signer.address.toString()).concat(" Does not have a FLOAT Collection in storage yet"))
    }

    execute {
        // Transfer the FLOAT NFT between Collections
        self.recipientCollection.deposit(token: <- self.providerCollection.withdraw(withdrawID: floatId))
        // DONE
    }
    
}
```

2. Using the Flovatar contract, write a transaction on Mainnet that properly sets up a user's NFT Collection.

In this case, since I need to save the collection to the user's Storage Path and link it afterwards, the user needs to sign the transaction and I need to do everything in the prepare phase because that's only when I have access to the AuthAccount:

* createFlovatarCollection.cdc

```cadence
import NonFungibleToken from 0x1d7e57aa55817448
import Flovatar from 0x921ea449dffec68a

transaction() {
    prepare(signer: AuthAccount) {
        // Create and save the Flovatar Collection straight to the signer's account
        signer.save<@NonFungibleToken.Collection>(<- Flovatar.createEmptyCollection(), to: Flovatar.CollectionStoragePath)

        // And link it to the Public Storage
        signer.link<&NonFungibleToken.Collection{Flovatar.CollectionPublic}>(Flovatar.CollectionPublicPath, target: Flovatar.CollectionStoragePath)
    }

    execute {
    }
}
```
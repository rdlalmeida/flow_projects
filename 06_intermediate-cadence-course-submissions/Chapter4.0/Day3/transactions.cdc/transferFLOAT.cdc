import FLOAT from "../../../../common_resources/contracts/FLOAT.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

// import FLOAT from 0x2d4c3caffbeab845
// import NonFungibleToken from 0x1d7e57aa55817448
// import MetadataViews from 0x1d7e57aa55817448

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
        // Trasfer the FLOAT NFT between Collections
        self.recipientCollection.deposit(token: <- self.providerCollection.withdraw(withdrawID: floatId))
        // DONE
    }
    
}
 
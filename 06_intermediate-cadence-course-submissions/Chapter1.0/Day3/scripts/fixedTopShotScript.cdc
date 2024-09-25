import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import TopShot from "../../../../common_resources/contracts/TopShot.cdc"
import MetadataViews from "../../../../common_resources/contracts/MetadataViews.cdc"

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
 
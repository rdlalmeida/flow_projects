/*
    Since I don't own any Goated Goats but I do have a ton of TopShot moments, I'm going to stuck my nose in this contracts instead. The important
    elements to retrieve here is the address of the main contract, or in the case of Flow, the account address where the main contracts for
    TopShot are deployed. A simple Google search, alongside with a confirmation using https://flow-view-source.com revealed that the main
    TopShot contracts are deployed in account 0xc1e4f4f4c4257510.
    The other important element to get is the address of my TopShot account, where all my TopShot NFTs are stored. To get this I've logged in
    the Dapper Wallet that I've been using for this purpose (https://accounts.meetdapper.com), selected 'Inventory' in the left side navigation
    pane, clicked on the '+' button on the top right side of the page (used to receive NFTs into this account) which revealed to be
    0x37f3f5b3e0eaf6ca
*/

// Note this import is local for code correction purposes. The flow.json that regulates this session has this contract properly set to its
// remote location in Flow's mainnet
import TopShot from "../contracts/TopShot.cdc"

pub fun main(collectionAddress: Address): TopShot.TopShotMomentMetadataView {
    // Begin by attempting to retrieve a capability to the Collection resource of the account provided as argument. According to the TopShot
    // contract, a capability can be retrieved from /public/MomentCollection
    let optionalReference = getAccount(collectionAddress).getCapability<&{TopShot.MomentCollectionPublic}>(/public/MomentCollection).borrow()

    // As always, test if a nil was returned and panic if it is the case
    if (optionalReference == nil) {
        panic(
            "Unable to retrieve a Collection capabilty from /public/MomentCollection for account "
            .concat(collectionAddress.toString())
        )
    }

    // The rest of this logic operates on the assumption that a valid collection reference was retrieved. This one is still in an optional
    // format. Force cast it to the proper format first
    let collectionReference: &{TopShot.MomentCollectionPublic} = (optionalReference)!

    // Cool. I have a proper Collection reference. Lets start by checking how many moments are stored in it
    let collectionIDs: [UInt64] = collectionReference.getIDs()

    let sizeMessage: String = 
        "Account's "
        .concat(collectionAddress.toString())
        .concat(" contains a collection with ")
        .concat(collectionIDs.length.toString())
        .concat(" NFTs in it")

    // Retrieve the metadata from the last NFT added to that collection (using their IDs as organizing element). Is it going to be the last
    // moment that I've purchased? Let's find out...
    let lastNftID: UInt64 = collectionIDs[collectionIDs.length - 1]

    let idMessage: String =
        "Account's "
        .concat(collectionAddress.toString())
        .concat(" last acquired NFT ID = ")
        .concat(lastNftID.toString())

    // Use the 'borrowMoment' function to get a reference to the TopShot.NFT resource with that id
    let lastMomentOptionalReference: &TopShot.NFT? = collectionReference.borrowMoment(id: lastNftID)

    // Same as before. Test if a proper NFT reference was returned. Panic if not
    if (lastMomentOptionalReference == nil) {
        panic(
            "Unable to retrieve metadata for NFT with ID"
            .concat(lastNftID.toString())
            .concat(" from account's ")
            .concat(collectionAddress.toString())
            .concat(" collection!")
        )
    }

    // All is good then. Force cast the reference to remove the optional and proceed to print out the NFT's metadata
    let lastMomentReference: &TopShot.NFT = lastMomentOptionalReference!

    // The TopShot.NFT resource has a very useful function called 'description', which produces a formatted string with the data
    // from the NFT in cause. Let's see if this works
    let NFTdescription: String = lastMomentReference.description()

    // All good. Return all the Strings created so far concatenated with each other
    log(sizeMessage)
    log(idMessage)
    log(NFTdescription)
    
    // Get the TopShotMetadataView resource for this NFT, which has a much more detailed information about it
    let nftViews: [Type] = lastMomentReference.getViews()

    log(
        "Retrieved the following views from NFT with ID"
        .concat(lastNftID.toString())
    )

    // Resolve the TopShotMomentMetadataView, which should be the second element of the last array
    let optionalResolvedView = lastMomentReference.resolveView(nftViews[nftViews.length - 1])
    
    if (optionalResolvedView == nil) {
        panic(
            "Unable to resolve a proper View for an NFT with id "
            .concat(lastNftID.toString())
            .concat(" from account ")
            .concat(collectionAddress.toString())
        )
    }

    // The View appears to be valid. It should be a TopShot.TopShotMomentMetadataView. Try to force cast the strut received to this type
    let resolvedView = optionalResolvedView!

    let topShotView: TopShot.TopShotMomentMetadataView = resolvedView as! TopShot.TopShotMomentMetadataView

    return topShotView
    // return "This message should never be returned! Check the code please!"
}
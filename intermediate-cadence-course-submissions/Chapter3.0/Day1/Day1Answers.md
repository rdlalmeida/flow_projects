1. Write a script that returns:

* a FLOAT NFT's reference
* FLOAT's total supply
* a Flovatar NFT's reference
* Flovatar's total supply
* Flow Token's total supply
* a reference to your public &FlowToken.Vault{FungibleToken.Receiver}
* a capability to your public Capability<&FlowToken.Vault{FungibleToken.Receiver}>

This one took a while, with all the contract importing and figuring out how to get the references to the Collection, but here it is:
(Just a side note: I actually had to use the concepts from the next day, i.e., Chp3, Day2, to be able to complete this one. Grabbing a reference to the FLOAT Collection was failing at first, because I was only getting a Capability to FLOAT.Collection - no interfaces included. Since I didn't have access to the transaction that created that collection in my account, I went and listed the PublicPaths and respective Types stored - stuff from future chapters - in order to understand which interfaces I needed to use in the borrow function.)

* getMainnetData.cdc

```cadence
import FLOAT from 0x2d4c3caffbeab845
import TopShot from 0x0b2a3299cc857e29
import FlowToken from 0x1654653399040a61
import FungibleToken from 0xf233dcee88fe0abe
import NonFungibleToken from 0x1d7e57aa55817448
import MetadataViews from 0x1d7e57aa55817448

pub fun main(): returnData {
    // My Blocto address for FLOATs and FlowTokens
    let bloctoAddress: Address = 0x82dd07b1bcafd968
    let bloctoAccount: PublicAccount = getAccount(bloctoAddress)
    
    // My Dapper Address for checking TopShot moments because I have tons of those but no Flovatars so far
    let dapperAddress: Address = 0x37f3f5b3e0eaf6ca
    let dapperAccount: PublicAccount = getAccount(dapperAddress)

    // Checking the aforementioned contracts, I see that the public paths (because I'm operating on a script, so no storage paths for you) for the requires elements are:
    let FLOATPublicPath: PublicPath = /public/FLOATCollectionPublicPath
    let FlowTokenVaultPublicPath: PublicPath = /public/flowTokenReceiver
    let TopShotCollectionPublicPath: PublicPath = /public/MomentCollection
    
    // Lets get to work.
    // FLOAT total supply:
    let floatSupply: UInt64 = FLOAT.totalSupply

    // And now a reference to the last FLOAT I acquired
    let FLOATCollectionRef: &FLOAT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, FLOAT.CollectionPublic} 
        = bloctoAccount.getCapability<&FLOAT.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, FLOAT.CollectionPublic}>(FLOATPublicPath).borrow() ??
            panic("Unable to retrive a public FLOAT collection reference for account ".concat(bloctoAddress.toString()))

    // Get the array of FLOAT Ids
    let FLOATids: [UInt64] = FLOATCollectionRef.getIDs()

    // Get the FLOAT NFT Reference
    let FLOATNFTReference: &FLOAT.NFT = FLOATCollectionRef.borrowFLOAT(id: FLOATids[FLOATids.length - 1]) ??
        panic("Unable to get a FLOAT Reference to NFT id = ".concat(FLOATids[FLOATids.length - 1].toString()))

    // Repeat the process to the TopShot stuff
    let topShotSupply: UInt64 = TopShot.totalSupply

    let topShotCollectionReference: &{TopShot.MomentCollectionPublic} = dapperAccount.getCapability<&{TopShot.MomentCollectionPublic}>(TopShotCollectionPublicPath).borrow() ??
        panic("Unable to retrieve a public TopShot collection reference for account ".concat(dapperAddress.toString()))
    
    let momentIds: [UInt64] = topShotCollectionReference.getIDs()
    let topShotNFTReference: &TopShot.NFT = topShotCollectionReference.borrowMoment(id: momentIds[momentIds.length - 1]) ??
        panic("Unable to get a TopShot Moment Reference to NFT id = ".concat(momentIds[momentIds.length - 1].toString()))

    // Now for the FlowToken stuff
    let flowTokenSupply: UFix64 = FlowToken.totalSupply

    let flowTokenVaultReceiverCapability: Capability<&FlowToken.Vault{FungibleToken.Receiver}> 
        = bloctoAccount.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(FlowTokenVaultPublicPath)

    let flowTokenVaultReceiverReference: &FlowToken.Vault{FungibleToken.Receiver} = flowTokenVaultReceiverCapability.borrow() ??
        panic("Unable to get a Reference to a FlowToken Vault for account ".concat(bloctoAddress.toString()))
    
    // Build and return the struct
    return returnData(
        floatRef: FLOATNFTReference,
        floatSupply: floatSupply,
        topShotSupply: topShotSupply,
        topShotNFTRef: topShotNFTReference,
        flowTokenSupply: flowTokenSupply,
        flowTokenVaultRecRef: flowTokenVaultReceiverReference,
        flowTokenVaultRecCap: flowTokenVaultReceiverCapability
    )
}

pub struct returnData {
    pub let FLOATNFTReference: &FLOAT.NFT
    pub let FLOATTotalSupply: UInt64
    pub let topShotTotalSupply: UInt64
    pub let topShotMomentRef: &TopShot.NFT
    pub let flowTokenTotalSupply: UFix64
    pub let flowTokenVaultReceiverReference: &FlowToken.Vault{FungibleToken.Receiver}
    pub let flowTokenVaultReceiverCapability: Capability<&FlowToken.Vault{FungibleToken.Receiver}>

    init(
        floatRef: &FLOAT.NFT,
        floatSupply: UInt64,
        topShotSupply: UInt64,
        topShotNFTRef: &TopShot.NFT,
        flowTokenSupply: UFix64,
        flowTokenVaultRecRef: &FlowToken.Vault{FungibleToken.Receiver},
        flowTokenVaultRecCap: Capability<&FlowToken.Vault{FungibleToken.Receiver}>
        ) {
        self.FLOATNFTReference = floatRef
        self.FLOATTotalSupply = floatSupply
        self.topShotTotalSupply = topShotSupply
        self.topShotMomentRef = topShotNFTRef
        self.flowTokenTotalSupply = flowTokenSupply
        self.flowTokenVaultReceiverReference = flowTokenVaultRecRef
        self.flowTokenVaultReceiverCapability = flowTokenVaultRecCap
    }
}
```

The result: 

![image](https://user-images.githubusercontent.com/39467168/226487095-9eeb321f-718f-4a16-87ab-77a0508fcbfa.png)

import StandardBow from "../contracts/StandardNFTInterface/StandardBow.cdc"
import StandardShield from "../contracts/StandardNFTInterface/StandardShield.cdc"
import StandardSword from "../contracts/StandardNFTInterface/StandardSword.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

pub fun main(collectionAddress: Address) {
    // Get the Public account to make things easier
    let collectionAccount: PublicAccount = getAccount(collectionAddress)

    // Here's why this approach required a shit ton of code just to check the total set of NFTs. Because I have three different Collection of three different types, 
    // which makes it impossible to do this check in a single cycle. Just like with the NFT creation, I need to repeat the same logic for evey type. Hopefully, 
    // my agnostic alternative solves this...
    // Also, the fact that I'm getting the collection references in different ways (sometimes I explicit the CollectionPublic, sometimes I don't), as well as
    // the variables used to store the NFT references (I've used vars and let interchangibly) is on purpose. I'm trying to see what works and don't in this
    // context.
    let swordCollectionReference: &StandardSword.Collection{StandardSword.CollectionPublic} 
        = collectionAccount.getCapability<&StandardSword.Collection{StandardSword.CollectionPublic}>(StandardSword.collectionPublic).borrow() ??
            panic("Account ".concat(collectionAddress.toString()).concat(" does not have a proper Sword Collection configured yet!"))

    let swordIDs: [UInt64] = swordCollectionReference.getIDs()

    log("NFTs in the Sword Collection: ")
    var swordNFTRef: &StandardSword.NFT? = nil

    for swordID in swordIDs {
        swordNFTRef = swordCollectionReference.borrowSwordNFT(id: swordID)
            ?? panic("Unable to get a Sword reference with id ".concat(swordID.toString()))

        log("NFT id = ".concat(swordID.toString()).concat(", of type = ").concat(swordNFTRef?.type!))
    }

    let shieldCollectionReference: &StandardShield.Collection{StandardShield.CollectionPublic} 
        = collectionAccount.getCapability<&StandardShield.Collection{StandardShield.CollectionPublic}>(StandardShield.collectionPublic).borrow() ??
            panic("Account ".concat(collectionAddress.toString()).concat(" does not have a proper Shield Collection configured yet!"))

    let shieldIDs: [UInt64] = shieldCollectionReference.getIDs()
    
    log("NFTs in the Shield Collection: ")

    var shieldNFTRef: &StandardShield.NFT? = nil

    for shieldID in shieldIDs {
        shieldNFTRef = shieldCollectionReference.borrowShieldNFT(id: shieldID) ??
            panic("Account ".concat(collectionAddress.toString()).concat(" does not have a Shield NFT with id ").concat(shieldID.toString()).concat(" in it."))

        log("NFT id = ".concat(shieldNFTRef?.id!.toString()).concat(", of type = ").concat(shieldNFTRef?.type!))
    }

    let bowCollectionReference: &StandardBow.Collection = collectionAccount.getCapability<&StandardBow.Collection>(StandardBow.collectionPublic).borrow() ??
        panic("Account ".concat(collectionAddress.toString()).concat(" does not have a proper Bow Collection configured yet!"))

    let bowIDs: [UInt64] = bowCollectionReference.getIDs()

    log("NFTs in the Bow Collection: ")

    var bowNFTRef: &StandardBow.NFT? = nil

    for bowID in bowIDs {
        bowNFTRef = bowCollectionReference.borrowBowNFT(id: bowID) ??
            panic("Account ".concat(collectionAddress.toString()).concat(" does not have a Bow NFT with id ").concat(bowID.toString()).concat(" in it."))

        log("NFT id = ".concat(bowNFTRef?.id!.toString()).concat(", of type = ").concat(bowNFTRef?.type!))
    }

}
 
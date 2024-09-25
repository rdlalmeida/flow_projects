import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"
import TestNFT from "../contracts/TestNFT.cdc"

pub fun main(collectionAddress: Address) {
    let testCollectionReference: &TestNFT.Collection{TestNFT.CollectionPublic} =
        getAccount(collectionAddress).getCapability<&TestNFT.Collection{TestNFT.CollectionPublic}>(TestNFT.collectionPublic).borrow() ??
            panic("Account ".concat(collectionAddress.toString()).concat(" does not have a proper Test Collection configured yet!"))
        
        let testNFTIDs: [UInt64] = testCollectionReference.getIDs()

        log("NFTs in the Test Collection: ")

        var testNFTRef: &TestNFT.NFT? = nil

        for testNFTID in testNFTIDs {
            testNFTRef = testCollectionReference.borrowTestNFT(id: testNFTID)
                ?? panic("Unable to get a Test NFT reference with id ".concat(testNFTID.toString()))

            log("NFT id = ".concat(testNFTRef?.id!.toString()).concat(", of type = ").concat(testNFTRef?.type!))

            // Check out the type of the NFT Reference returned
            log("This NFT has type = ".concat(testNFTRef.getType().identifier))
        }

        let someType: Type = Type<@TestNFT.NFT>()

        log("Some type = ".concat(someType.identifier))

        
}
 
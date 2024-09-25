import MyBow from "../contracts/MyNewNFTInterface/MyBow.cdc"
import MyShield from "../contracts/MyNewNFTInterface/MyShield.cdc"
import MySword from "../contracts/MyNewNFTInterface/MySword.cdc"
import MyCollection from "../contracts/MyNewNFTInterface/MyCollection.cdc"
import NonFungibleTokenSimple from "../../../../common_resources/contracts/NonFungibleTokenSimple.cdc"

pub fun main(collectionAddress: Address) {
    let collectionRef: &MyCollection.Collection{MyCollection.CollectionPublic}
        = getAccount(collectionAddress).getCapability<&MyCollection.Collection{MyCollection.CollectionPublic}>(MyCollection.myCollectionPublic)
            .borrow() ?? panic("Account ".concat(collectionAddress.toString()).concat(" does not have a Collection configured yet"))

    // Grab an array of all the token Types currently in the Collection
    let tokenTypes: [Type] = collectionRef.getAllTokenTypes()

    // Next, run this in cycles
    for tokenType in tokenTypes {
        // Here's the first "limitation" of this approach: because I know the set of NFT types this Collection is limited, I can use this to cycle through
        // all the tokens in this collection by determining their type, and from there use the proper borrow function
        // Use the first tokenType to retrieve the first 
        log("Got this type in the collection: ".concat(tokenType.identifier))

        // Lets use a switch to determine which borrow function should be used to retrieve the actual NFT data
        switch(tokenType) {
            case Type<@MyBow.NFT>():
                let tokenIds: [String]? = collectionRef.getAllTokenIDs(tokenType: tokenType)
                if (tokenIds != nil) {
                    var bowNFTref: &MyBow.NFT? = nil

                    for tokenId in tokenIds! {
                        // Because I know I'm in the Bow switch, I need to use the corresponding borrow function to get the NFT details
                        bowNFTref = collectionRef.borrowBowNFT(id: tokenId)

                        log(
                            "NFT id = "
                            .concat(bowNFTref!.id)
                            .concat(", is a ")
                            .concat(bowNFTref!.name)
                        )
                    }
                }
                else {
                    log("There are no tokens stored under token type ".concat(tokenType.identifier))
                }
            case Type<@MyShield.NFT>():
                let tokenIds: [String]? = collectionRef.getAllTokenIDs(tokenType: tokenType)
                if (tokenIds != nil) {
                    var shieldNFTref: &MyShield.NFT? = nil

                    for tokenId in tokenIds! {
                        shieldNFTref = collectionRef.borrowShieldNFT(id: tokenId)

                        log(
                            "NFT id = "
                            .concat(shieldNFTref!.id)
                            .concat(", is a ")
                            .concat(shieldNFTref!.name)
                        )
                    }
                }
                else {
                    log("There are no token stored under token type ".concat(tokenType.identifier))
                }
            case Type<@MySword.NFT>():
                let tokenIds: [String]? = collectionRef.getAllTokenIDs(tokenType: tokenType)
                if (tokenIds != nil) {
                    var swordNFTref: &MySword.NFT? = nil

                    for tokenId in tokenIds! {
                        swordNFTref = collectionRef.borrowSwordNFT(id: tokenId)

                        log(
                            "NFT id = "
                            .concat(swordNFTref!.id)
                            .concat(", is a ")
                            .concat(swordNFTref!.name)
                        )
                    }
                }
                else {
                    log("There are no token stored under token type ".concat(tokenType.identifier))
                }
            default: 
                log(
                    "This branch should never be reached. Type "
                    .concat(tokenType.identifier)
                    .concat(" is not predicted in this Collection")
                )
        }

        log("---------------------------------------------------------------------------------------")
    }
}
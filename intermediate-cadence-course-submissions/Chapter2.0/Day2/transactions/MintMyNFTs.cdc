import MyCollection from "../contracts/MyNewNFTInterface/MyCollection.cdc"
import MyAdmin from "../contracts/MyNewNFTInterface/MyAdmin.cdc"
import MyBow from "../contracts/MyNewNFTInterface/MyBow.cdc"
import MyShield from "../contracts/MyNewNFTInterface/MyShield.cdc"
import MySword from "../contracts/MyNewNFTInterface/MySword.cdc"

transaction(recipient: Address) {

    let myCollection: &MyCollection.Collection{MyCollection.CollectionPublic}
    let adminMinter: &MyAdmin.NFTMinter

    prepare(signer: AuthAccount) {
        self.myCollection = getAccount(recipient).getCapability<&MyCollection.Collection{MyCollection.CollectionPublic}>(MyCollection.myCollectionPublic).borrow() ??
            panic("Account ".concat(recipient.toString()).concat(" does not have a proper Collection set up yet!"))

        self.adminMinter = signer.getCapability<&MyAdmin.NFTMinter>(MyAdmin.minterPrivate).borrow() ??
            panic("Acount ".concat(signer.address.toString()).concat(" does not have a proper NFT Minter set up in private storage yet!"))
    }

    execute {
        // Mint a bunch of different NFTs and deposit all of them into the same Collection, something that was not possible before
        let bow1: @MyBow.NFT <- self.adminMinter.mintBow()
        let bow2: @MyBow.NFT <- self.adminMinter.mintBow()

        self.myCollection.deposit(token: <- bow1)
        self.myCollection.deposit(token: <- bow2)

        let shield1: @MyShield.NFT <- self.adminMinter.mintShield()
        let shield2: @MyShield.NFT <- self.adminMinter.mintShield()
        let shield3: @MyShield.NFT <- self.adminMinter.mintShield()

        self.myCollection.deposit(token: <- shield1)
        self.myCollection.deposit(token: <- shield2)
        self.myCollection.deposit(token: <- shield3)

        let sword1: @MySword.NFT <- self.adminMinter.mintSword()
        let sword2: @MySword.NFT <- self.adminMinter.mintSword()
        let sword3: @MySword.NFT <- self.adminMinter.mintSword()
        let sword4: @MySword.NFT <- self.adminMinter.mintSword()

        self.myCollection.deposit(token: <- sword1)
        self.myCollection.deposit(token: <- sword2)
        self.myCollection.deposit(token: <- sword3)
        self.myCollection.deposit(token: <- sword4)
    }
}
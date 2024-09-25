import MyBow from "./MyBow.cdc"
import MyShield from "./MyShield.cdc"
import MySword from "./MySword.cdc"
pub contract MyAdmin {
    pub let minterStorage: StoragePath
    pub let minterPrivate: PrivatePath

    pub event MyBowCreated()
    pub event MyShieldCreated()
    pub event MySwordCreated()

    pub event NFTMinterCreated()

    pub resource NFTMinter {
        pub fun mintBow(): @MyBow.NFT {
            let bow: @MyBow.NFT <- MyBow.createBow()
            emit MyBowCreated()
            return <- bow
        }

        pub fun mintShield(): @MyShield.NFT {
            let shield: @MyShield.NFT <- MyShield.createShield()
            emit MyShieldCreated()
            return <- shield
        }

        pub fun mintSword(): @MySword.NFT {
            let sword: @MySword.NFT <- MySword.createSword()
            emit MySwordCreated()
            return <- sword
        }
    }

    init() {
        self.minterStorage = /storage/myNFTMinter
        self.minterPrivate = /private/myNFTMinter

        let randomMinter: @AnyResource <- self.account.load<@AnyResource>(from: self.minterStorage)
        destroy randomMinter
        self.account.unlink(self.minterPrivate)

        let minter: @NFTMinter <- create NFTMinter()
        self.account.save(<- minter, to: self.minterStorage)

        self.account.link<&NFTMinter>(self.minterPrivate, target: self.minterStorage)

        emit NFTMinterCreated()
    }


}

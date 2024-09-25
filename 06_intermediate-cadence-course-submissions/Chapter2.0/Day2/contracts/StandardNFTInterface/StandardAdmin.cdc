import StandardBow from "./StandardBow.cdc"
import StandardSword from "./StandardSword.cdc"
import StandardShield from "./StandardShield.cdc"

pub contract StandardAdmin {
    pub let minterStorage: StoragePath
    pub let minterPrivate: PrivatePath

    pub event StandardSwordCreated()
    pub event StandardBowCreated()
    pub event StandardShieldCreated()
    pub event NFTMinterCreated()

    pub resource NFTMinter {
        pub fun mintSword(): @StandardSword.NFT {
            let sword: @StandardSword.NFT <- StandardSword.createSword()
            emit StandardSwordCreated()
            return <- sword
        }

        pub fun mintBow(): @StandardBow.NFT {
            let bow: @StandardBow.NFT <- StandardBow.createBow()
            emit StandardBowCreated()
            return <- bow
        }

        pub fun mintShield(): @StandardShield.NFT {
            let shield: @StandardShield.NFT <- StandardShield.createShield()
            emit StandardShieldCreated()
            return <- shield
        }
    }

    init() {
        self.minterStorage = /storage/nftMinter
        self.minterPrivate = /private/nftMinter

        let randomMinter: @AnyResource <- self.account.load<@AnyResource>(from: self.minterStorage)
        destroy randomMinter
        self.account.unlink(self.minterPrivate)

        let minter: @NFTMinter <- create NFTMinter()
        self.account.save(<- minter, to: self.minterStorage)

        // Link the NFT Minter to the private storage for future use in proper fashion
        self.account.link<&NFTMinter>(self.minterPrivate, target: self.minterStorage)

        emit NFTMinterCreated()
    }
}
 
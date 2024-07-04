/*
    Transaction to buy a Square from the Shapes contract account into the signer's collection
*/

import Shapes from "../contracts/Shapes.cdc"
import FungibleToken from "../../float/src/cadence/core-contracts/FungibleToken.cdc"
import FlowToken from "../../float/src/cadence/core-contracts/FlowToken.cdc"

transaction(adminAddress: Address) {
    let shapeCollectionRef: &Shapes.Collection
    let flowVaultRef: &FlowToken.Vault
    let squarePrice: UFix64?
    let adminRef: &Shapes.Admin{Shapes.AdminPublic}
    prepare(signer: AuthAccount) {
        // Get a reference to the signer's Shapes Collection
        self.shapeCollectionRef = signer.getCapability<&Shapes.Collection>(Shapes.collectionPublic).borrow() ??
            panic("Account ".concat(signer.address.toString()).concat(" does not have a Shapes Collection set up yet!"))

        // And to the signer's Flow Vault. Because this storage path is not know/stored anywhere, we need to be creative to find it
        var vaultStoragePath: StoragePath? = nil
        var count: UInt64 = 0

        let iterFunction = fun (path: StoragePath, type: Type): Bool {
            if (type == Type<@FlowToken.Vault>()) {
                // Iterate until a storage path of the required type is found
                vaultStoragePath = path

                return false
            }
            return true
        }

        signer.forEachStored(iterFunction)

        assert(
            vaultStoragePath != nil,
            message: "Unable to find a FlowToken.Vault in user ".concat(signer.address.toString()).concat(" account")
        )

        // Borrow the reference from the Storage path
        self.flowVaultRef = signer.borrow<&FlowToken.Vault>(from: vaultStoragePath!) ??
            panic("Unable to retrieve a reference to the FlowToken.Vault for account ".concat(signer.address.toString()))

        // Get the price of a Square, validating also if there are enough squares to buy
        self.squarePrice = Shapes.getSquarePrice()

        // log("Squares cost ".concat(self.squarePrice == nil ? "nil" : self.squarePrice!.toString()).concat(" Flow!"))

        assert(
            self.squarePrice != nil,
            message: "There are no more Squares left to buy!"
        )

        // Get the reference for the Admin resource in the Public Path
        self.adminRef = getAccount(adminAddress).getCapability<&Shapes.Admin{Shapes.AdminPublic}>(Shapes.adminPublic).borrow() ??
            panic("Unable to get a Public Admin Reference for account ".concat(adminAddress.toString()))
    }

    execute {
        // Withdraw the neccesary tokens for the Square purchase
        let payment: @FungibleToken.Vault <- self.flowVaultRef.withdraw(amount: self.squarePrice!)

        // Proceed with the buy
        let squareId: UInt64 = self.adminRef.buySquare(recipient: self.shapeCollectionRef, payment: <- payment)

        log("Bough Square with id ".concat(squareId.toString()))
    }
}
 
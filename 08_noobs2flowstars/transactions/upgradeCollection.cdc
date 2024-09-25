/*
    Transaction that upgrades the signer's account, using the rules defined in the Admin function that does this process, namely,
    Square -> Triangle -> Pentagon -> Circle -> Star, if there are shapes available for it
*/

import Shapes from "../contracts/Shapes.cdc"

transaction(accountToUpgrade: Address) {
    let collectionRef: &Shapes.Collection
    let adminRef: &Shapes.Admin

    prepare(signer: AuthAccount) {
        // Retrieve the references for the Collection and Admin resources in the prepare phase
        self.collectionRef = getAccount(accountToUpgrade).getCapability<&Shapes.Collection>(Shapes.collectionPublic).borrow() ??
            panic("Account ".concat(accountToUpgrade.toString()).concat(" does not has a Collection set yet!"))

        self.adminRef = signer.getCapability<&Shapes.Admin>(Shapes.adminPublic).borrow() ??
            panic("Admin account ".concat(signer.address.toString()).concat(" does not has a Admin resource configured yet!"))
    }

    execute {
        self.adminRef.upgradeCollection(collectionRef: self.collectionRef)
    }
}

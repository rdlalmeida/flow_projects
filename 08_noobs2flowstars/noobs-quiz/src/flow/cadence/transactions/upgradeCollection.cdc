import Shapes from 0xShapes

transaction(adminAccount: Address) {
    let collectionRef: &Shapes.Collection
    let adminRef: &Shapes.Admin{Shapes.AdminPublic}

    prepare(signer: AuthAccount) {
        // Retrieve the references for the Collection and Admin resources in the prepare phase
        self.collectionRef = signer.getCapability<&Shapes.Collection>(Shapes.collectionPublic).borrow() ??
            panic("Account ".concat(signer.address.toString()).concat(" does not has a Collection set yet!"))

        self.adminRef = getAccount(adminAccount).getCapability<&Shapes.Admin{Shapes.AdminPublic}>(Shapes.adminPublic).borrow() ??
            panic("Admin account ".concat(adminAccount.toString()).concat(" does not has a Admin resource configured yet!"))
    }

    execute {
        self.adminRef.upgradeCollection(collectionRef: self.collectionRef)
    }
}

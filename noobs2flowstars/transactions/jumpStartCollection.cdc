/* 
    Transaction the jump starts a transaction by depositing a Square into it. The validations are all done contract side, i.e., defined in the Admin resource
    that contains the functions to run this functionality
    This transaction needs to be run by the deployer account, i.e.,t the admin with access to the Admin resource in private storage
*/

import Shapes from "../contracts/Shapes.cdc"

transaction(accountToJumpStart: Address) {
    let collectionReference: &Shapes.Collection
    let adminReference: &Shapes.Admin

    prepare(signer: AuthAccount) {
        self.collectionReference = getAccount(accountToJumpStart).getCapability<&Shapes.Collection>(Shapes.collectionPublic).borrow() ??
            panic("Account ".concat(accountToJumpStart.toString()).concat(" does not have a Collection set up yet!"))

        self.adminReference = signer.getCapability<&Shapes.Admin>(Shapes.adminPrivate).borrow() ??
            panic("Admin account ".concat(signer.address.toString()).concat(" does not have an Admin resource set up yet!"))
    }

    execute {
        // Use the Admin resource to deposit a Square from the contract storage to the user account provided
        self.adminReference.depositSquare(collectionRef: self.collectionReference)
    }
}
 
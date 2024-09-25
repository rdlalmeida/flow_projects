import Shapes from 0xShapes

pub fun main(accountToCheck: Address): Bool {
    let collectionRef: &Shapes.Collection? = getAccount(accountToCheck).getCapability<&Shapes.Collection>(Shapes.collectionPublic).borrow()

    if (collectionRef == nil) {
        return false
    }
    else {
        return true
    }

}

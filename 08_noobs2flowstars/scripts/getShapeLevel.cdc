/*
    Script that returns the level in which the user is:
    0 - no Shapes (needs to buy a Square)
    1 - Has a Square...
*/

import Shapes from "../contracts/Shapes.cdc"

pub fun main(collectionAddress: Address): UInt64 {
    let collectionRef: &Shapes.Collection = getAccount(collectionAddress).getCapability<&Shapes.Collection>(Shapes.collectionPublic).borrow() ??
        panic("Account ".concat(collectionAddress.toString()).concat(" does not has a Collection configured yet!"))

    if (collectionRef.borrowSquare() != nil) {
        return 1
    }

    if (collectionRef.borrowTriangle() != nil) {
        return 2
    }

    if (collectionRef.borrowPentagon() != nil) {
        return 3
    }

    if (collectionRef.borrowCircle() != nil) {
        return 4
    }

    if (collectionRef.borrowStar() != nil) {
        return 5
    }

    return 0
}
 
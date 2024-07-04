/*
    Script to determine the status of a Collection, namely, which shape is in there, if any. If a shape is detected it prints out which one it is (type and id) and
    also the score associated to it
*/

import Shapes from "../contracts/Shapes.cdc"

pub fun main(accountToCheck: Address) {
    let collectionRef: &Shapes.Collection = getAccount(accountToCheck).getCapability<&Shapes.Collection>(Shapes.collectionPublic).borrow() ??
        panic("Account ".concat(accountToCheck.toString()).concat(" does not has a Collection configured yet!"))

    // Detect which shape is in there, if any
    let square: &Shapes.Square? = collectionRef.borrowSquare()
    let triangle: &Shapes.Triangle? = collectionRef.borrowTriangle()
    let pentagon: &Shapes.Pentagon? = collectionRef.borrowPentagon()
    let circle: &Shapes.Circle? = collectionRef.borrowCircle()
    let star: &Shapes.Star? = collectionRef.borrowStar()

    log("Shapes in account: ")
    if (square != nil) {
        log("Square with id ".concat(square!.id.toString()))
    }

    if (triangle != nil) {
        log("Triangle with id ".concat(triangle!.id.toString()))
    }

    if (pentagon != nil) {
        log("Pentagon with id ".concat(pentagon!.id.toString()))
    }

    if (circle != nil) {
        log("Circle with id ".concat(circle!.id.toString()))
    }

    if (star != nil) {
        log("Star with id ".concat(star!.id.toString()))
    }

    // Validate the Collection by counting the number of shapes in it. If its different than 0 or 1, inform the user
    let shapeCount: Int = collectionRef.getShapeCount()

    log("Collection status: ")
    if (shapeCount == 0) {
        log("The collection is still empty")
    }
    else {
        if (shapeCount == 1) {
            log("The Collection is valid. It contains a single shape")
        }
        else {
            log("Invalid Collection detected: There are ".concat(shapeCount.toString()).concat(" shapes in it!"))
        }
    }

    log("Current Collection score:")
    log(collectionRef.score.toString().concat(" points"))
}

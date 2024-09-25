/*
    Script to retrieve and print out the contract status, namely, the size, types and counts of
    every internal shape storage dictionary
*/

import Shapes from "../contracts/Shapes.cdc"

pub fun main(): Void {
    let shapeCounts: {String: Int} = Shapes.getContractShapeCounts()

    for type in shapeCounts.keys {
        log(type.concat(" has ").concat(shapeCounts[type]!.toString()).concat(" shapes in it"))
    }
}
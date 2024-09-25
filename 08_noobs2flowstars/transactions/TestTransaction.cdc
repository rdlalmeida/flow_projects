/*
    Simple test transaction to test stuff before implementing it
*/

import TestContract from "../contracts/TestContract.cdc"

transaction(anotherUser: Address) {
    prepare(signer: AuthAccount) {
        let testNFT: @TestContract.TestNFT <- TestContract.createTestNFT()

        log("TestNFT type is ".concat(testNFT.getType().identifier))

        log("TestNFT short type is ".concat(TestContract.getShortType(shapeType: testNFT.getType())))

        destroy testNFT

        log("Deployer/signer address is ".concat(TestContract.returnDeployerAddress()))

        log("The other user's address: ".concat(anotherUser.toString()))

    }

    execute {

    }
}
 
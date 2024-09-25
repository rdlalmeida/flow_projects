import TestContract from 0xShapes

transaction() {
    prepare(signer: AuthAccount) {
        let testNFT: @TestContract.TestNFT <- TestContract.createTestNFT()

        log("TestNFT type is ".concat(testNFT.getType().identifier))

        log("TestNFT short type is ".concat(TestContract.getShortType(shapeType: testNFT.getType())))

        destroy testNFT

        log("Deployer/signer address is ".concat(TestContract.returnDeployerAddress()))

        log("The other user's address: ".concat(anotherUser.toString()))

        log("All is correct!")

    }

    execute {

    }
}
 
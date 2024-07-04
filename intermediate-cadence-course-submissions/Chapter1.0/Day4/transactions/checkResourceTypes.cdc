import ResourceTypes from "../contracts/ResourceTypes.cdc"

transaction(name1: String, name2: String) {
    prepare(signer: AuthAccount) {
        // Create two different resources from the same contract but with the same type 
        let resource01: @ResourceTypes.ExampleResource <- ResourceTypes.createExampleResource(name: name1)

        let resource02: @ResourceTypes.ExampleResource <- ResourceTypes.createExampleResource(name: name2)

        // Lets check their types then

        log("Resource 01 (name = ".concat(resource01.name).concat(") identifier: ".concat(resource01.getType().identifier)))
        log("Resource 02 (name = ".concat(resource02.name).concat(") identifier: ".concat(resource02.getType().identifier)))

        destroy resource01
        destroy resource02
    }

    execute {

    }
}
import MyStorage from "../contracts/MyStorage.cdc"

transaction() {

  prepare(signer: AuthAccount) {

    let testResource <- MyStorage.createTest()
    signer.save(<- testResource, to: /storage/MyTestResource) 
    // saves `testResource` to my account storage at this path:
    // /storage/MyTestResource

    let testResource2 <- signer.load<@MyStorage.Test?>(from: /storage/MyTestResource)
                     ?? panic("A `@MyStorage.Test` resource does not live here.")
    // takes `testResource` out of my account storage

    // let testResource3 <- (testResource2 as @MyStorage.Test?)!
    let testResource3 <-! testResource2

    // log the 'name' field of the resource
    log(testResource3.name)

    // destroy resource
    destroy testResource3

  }

  execute {

  }
}

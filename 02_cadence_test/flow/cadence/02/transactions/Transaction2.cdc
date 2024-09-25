import MyStorage from "../contracts/MyStorage.cdc"

transaction() {

  // I added some extra logic to the code for a test purpose.
  prepare(signer: AuthAccount) {

    // get the reference of the resource. It is possible that there is no resource in the storage. Let's see...
    let testResource1: &MyStorage.Test? = signer.borrow<&MyStorage.Test?>(from: /storage/MyTestResource)!
    // if there is no resource of type MyStorage.Test saved at '/storage/MyTestResource'
    if testResource1 == nil {

      // create resource
      let testResource <- MyStorage.createTest()

      // get the reference of the newly created resource
      signer.save(<- testResource, to: /storage/MyTestResource) 
      let testResource2 = signer.borrow<&MyStorage.Test>(from: /storage/MyTestResource) as &MyStorage.Test?

    //   // log the field 'count' from the resource
    //   log(testResource2.count)
    //   log("The resource didn't exist before. We have just created it")

        log("Got a nil here!")

    } else {     // if there was already a resource at '/storage/MyTestResource', log the field 'name' from the resource

        log(testResource1!.name)  
        // unwraps optional and shows name
    }
    

    log("OK!")
  }

  execute {

  }
}
import "HelloWorld"

transaction(greeting: String) {

  prepare(signer: AuthAccount) {
    log(signer.address)
  }

  execute {
    HelloWorld.changeGreeting(newGreeting: greeting)
  }
}

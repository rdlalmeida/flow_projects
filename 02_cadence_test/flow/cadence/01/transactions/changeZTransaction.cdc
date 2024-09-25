import SomeContract from "../contracts/SomeContract.cdc"

transaction(newZ: String) {
  prepare(account: AuthAccount) {
    SomeContract.testStruct.publicFunc(newZ: newZ)
  }

  execute {
  }
}
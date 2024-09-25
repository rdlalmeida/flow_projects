pub contract MyStorage {

  pub resource Test {
    pub var name: String
    pub var count: UInt

    init() {
      self.name = "Test3"
      self.count = 0
    }
  }

  pub fun createTest(): @Test? {
    return <- create Test()
  }

}
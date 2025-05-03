access(all) contract ExampleContract {
    
    access(all) let param1: [Int]

    init(par1: [Int]) {
        self.param1 = par1
    }
}
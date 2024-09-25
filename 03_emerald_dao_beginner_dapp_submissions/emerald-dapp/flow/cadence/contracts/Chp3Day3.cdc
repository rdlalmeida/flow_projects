pub contract Chp3Day3 {
    pub var state: String
    pub var index: UInt64

    init() {
        self.state = "Chapter 3, Day 3"
        self.index = 1
    }

    pub fun changeState(newState: String) {
        self.state = newState
    }

    pub fun changeIndex(newIndex: UInt64) {
        self.index = newIndex
    }
}
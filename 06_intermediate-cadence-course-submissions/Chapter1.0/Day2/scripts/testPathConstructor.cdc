pub fun main(): Void {
    let number: UInt64 = 123
    let baseString: String = "/storage/path".concat(number.toString())

    var basePath: StoragePath? = StoragePath(identifier: baseString)

    // This one is OK! Why? Why not the one that I've build???
    let privPath: PrivatePath = /private/NFTMinter123

    if (basePath == nil) {
        log("The base path is nil! What the fuck!")
    }
    else {
        log("I just build this path: ".concat(basePath!.toString()))
    }
}
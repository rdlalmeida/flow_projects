// HelloWorld.cdc

pub contract HelloWorld {
    // Declare a public field of type String
    //
    // All fields must be initialized in the init() function
    pub var greeting: String

    // The init() function is required if the contract contains any fields
    init() {
        self.greeting = "Go fuck yourself stupid world!"
    }

    // Public function that returns our friendly greeting!
    pub fun hello(): String {
        return self.greeting
    }

    pub fun changeGreeting(newGreeting: String): Void {
        self.greeting = newGreeting
    }
}
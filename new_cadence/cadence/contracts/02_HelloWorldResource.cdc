access(all)
contract HelloWorldResource {
    
    // Define a contract based resource
    access(all)
    resource HelloAsset {
        access(all)
        view fun hello(): String {
            return "Hello World!"
        }
    }

    access(all)
    fun createHelloAsset(): @HelloAsset {
        return <- create HelloAsset()
    }
}
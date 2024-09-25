import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
// import FungibleToken from 0xf233dcee88fe0abe


pub fun main(user: Address): UFix64 {
    // As it is indicated, I need to retrieve the Vault as &AnyResource because of a bad public link
    let vault = getAccount(user).getCapability(/public/Vault)
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Your Vault is not set up correctly")

    // I got something back. Make sure its the correct type with an assert. First, I need to "build" the String to compare using a bit of code gymnastics
    // First, get the user's short address, i.e., without the '0x' prefix
    let userShortAddress: String = user.toString().slice(from: 2, upTo: user.toString().length)

    // Compose the type to compare
    let expectedType: String = "A.".concat(userShortAddress).concat(".FungibleToken.Vault")

    // Finally assert the thing
    assert(
        vault.getType().identifier == expectedType, message: "The resource borrowed does not have the expected type: Expected '"
            .concat(expectedType).concat("', got a '").concat(vault.getType().identifier).concat("' instead")
    )

    return vault.balance
}
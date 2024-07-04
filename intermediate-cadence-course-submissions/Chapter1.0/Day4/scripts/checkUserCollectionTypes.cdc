import ResourceTypes from "../contracts/ResourceTypes.cdc"

pub fun main(user: Address): Void {
    let userAddress: String = user.toString()

    log("User's complete address is ".concat(userAddress))

    // Lets try and remove the '0x' portion of the user address using the String.slice() function

    let shortUserAddress: String = userAddress.slice(from: 2, upTo: userAddress.length)

    log("User's short Address is ".concat(shortUserAddress))
}
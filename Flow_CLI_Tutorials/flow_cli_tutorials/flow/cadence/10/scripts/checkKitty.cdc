/*
    Simple script that prints out the collection of Kitties stored in the input argument's account
*/
import KittyVerse from "../contracts/KittyVerse.cdc"

pub fun main(targetAccount: Address) {
    let kittyCollectionReference: &KittyVerse.KittyCollection{KittyVerse.KittyReceiver} = 
        getAccount(targetAccount).getCapability<&KittyVerse.KittyCollection{KittyVerse.KittyReceiver}>(KittyVerse.kittyCollectionPublic).borrow() ??
            panic(
                "Account '"
                .concat(targetAccount.toString())
                .concat("' does not have a Kitty Collection in its public path! Cannot continue...")
            )

    // The rest is easy because I've written a shit load of function to print stuff out
    log(kittyCollectionReference.getAllKittiesAndHats())
}
 
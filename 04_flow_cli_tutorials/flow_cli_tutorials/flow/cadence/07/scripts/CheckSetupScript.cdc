import ExampleToken from "../../06/contracts/ExampleToken.cdc"
import ExampleNFT from "../../05/contracts/ExampleNFT.cdc"

/*
    This script checks that the accounts are set up correctly for the marketplace tutorial.
*/

pub fun main(address1: Address, address2: Address) {
    // Get the account's public account objects
    let account1 = getAccount(address1)
    let account2 = getAccount(address2)

    /*
        Get references to the account's receivers by getting their public capability and borrowing a reference from the capability
    */
    let account1ReceiverRef = account1.getCapability(ExampleToken.VaultPublicPath)
                .borrow<&ExampleToken.Vault{ExampleToken.Balance}>()
                ?? panic("Could not borrow account1 vault reference!")

    let account2ReceiverRef = account2.getCapability(ExampleToken.VaultPublicPath)
                .borrow<&ExampleToken.Vault{ExampleToken.Balance}>()
                ?? panic("Could not borrow account2 vault reference!")

    // Log the Vault balance of both accounts and ensure that thet are the correct numbers
    log("Account 1 Balance: ".concat(account1ReceiverRef.balance.toString()))
    log("Account 2 Balance: ".concat(account2ReceiverRef.balance.toString()))

    // Verify that the balances are correct
    if (account1ReceiverRef.balance <= 0.0) || (account2ReceiverRef.balance <= 0.0) {
        panic("Wrong balances!")
    }

    // Find the public Receiver capability for their Collections
    let account1Capability = account1.getCapability(ExampleNFT.CollectionPublicPath)
    let account2Capability = account2.getCapability(ExampleNFT.CollectionPublicPath)

    // Borrow references from the capabilities
    let nft1Ref = account1Capability.borrow<&{ExampleNFT.NFTReceiver}>() ?? panic("Could not borrow account 1 NFT collection reference.")
    let nft2Ref = account2Capability.borrow<&{ExampleNFT.NFTReceiver}>() ?? panic("Could not borrow account 2 NFT collection reference·")

    // Print both collections as arrays of IDs
    log("Account 1 NFTs: ")
    log(nft1Ref.getIDs())

    log("Account 2 NFTs: ")
    log(nft2Ref.getIDs())
}
import ExampleToken from "../../06/contracts/ExampleToken.cdc"
import ExampleNFT from "../../05/contracts/ExampleNFT.cdc"

/*
    This transaction mint tokens for both accounts using the minter stored on the signer's account
*/
transaction(receiverAddress: Address, amount1: UFix64, amount2: UFix64) {
    // Public Vault Receiver References for both accounts
    let account1Capability: Capability<&AnyResource{ExampleToken.Receiver}>
    let account2Capability: Capability<&AnyResource{ExampleToken.Receiver}>

    // Private minter references for this account to mint tokens
    let minterRef: &ExampleToken.VaultMinter

    let account1Address: Address
    let account2Address: Address

    prepare(account: AuthAccount) {
        // Get the public object for input address
        let account2 = getAccount(receiverAddress)

        self.account1Address = account.address
        self.account2Address = receiverAddress

        // Retrieve public Vault Receiver references for both accounts
        self.account1Capability = account.getCapability<&AnyResource{ExampleToken.Receiver}>(ExampleToken.VaultPublicPath)
        self.account2Capability = account2.getCapability<&AnyResource{ExampleToken.Receiver}>(ExampleToken.VaultPublicPath)

        // Get the stored Minter reference for the signer account
        self.minterRef = account.borrow<&ExampleToken.VaultMinter>(from: ExampleToken.VaultMinterStoragePath)
            ?? panic("Could not borrow owner's vault minter reference")
    }

    execute {
        // Mint tokens for both accounts
        self.minterRef.mintTokens(amount: amount1, recipient: self.account2Capability)

        self.minterRef.mintTokens(amount: amount2, recipient: self.account1Capability)

        log("Minted new fungible tokens for account 1 and 2")
    }
}
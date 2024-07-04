import FlowToken from "../../float/src/cadence/core-contracts/FlowToken.cdc"
import FungibleToken from "../../float/src/cadence/core-contracts/FungibleToken.cdc"

transaction(recipient: Address, recipientVaultPublic: PublicPath, amount: UFix64) {
    let minterRef: &FlowToken.Minter
    let recipientVaultRef: &FlowToken.Vault{FungibleToken.Receiver}

    prepare(signer: AuthAccount) {
        // Borrow a reference to the Flow Vault receiver
        self.recipientVaultRef = getAccount(recipient).getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(recipientVaultPublic).borrow() ??
            panic("Unable to retrieve a reference to the FlowToken.Vault for account ".concat(recipient.toString()))

        // Borrow a reference to the minter
        self.minterRef = signer.borrow<&FlowToken.Minter>(from: FlowToken.minterStorage) ??
            panic("Unable to borrow a Minter reference for account ".concat(signer.address.toString()))
        
    }

    execute {
        // Mint the required tokens to the recipient's vault
        let tokens: @FlowToken.Vault <- self.minterRef.mintTokens(amount: amount)

        self.recipientVaultRef.deposit(from: <- tokens)

        log("Deposited ".concat(amount.toString()).concat(" test FLOW into ".concat(recipient.toString())).concat(" Vault!"))
    }
}
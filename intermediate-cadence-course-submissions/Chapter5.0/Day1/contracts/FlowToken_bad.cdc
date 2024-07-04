/*
    This dumb contract is undeployable by some stupid reason...
*/

// import FungibleToken from 0xf233dcee88fe0abe
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"

pub contract FlowToken_bad: FungibleToken {

    // Total supply of Flow tokens in existence
    pub var totalSupply: UFix64

    // Event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    // Event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    // Event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    // Event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)

    // Event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64)

    // Event that is emitted when a new burner resource is created
    pub event BurnerCreated()

    pub let devMode: Bool

    pub let vaultStorage: StoragePath
    pub let adminStorage: StoragePath
    pub let vaultBalancePublic: PublicPath
    pub let vaultReceiverPublic: PublicPath

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        // holds the balance of a users tokens
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault: @FlowToken_bad.Vault <- from as! @FlowToken_bad.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy (vault)
        }

        destroy() {
            if self.balance > 0.0 {
                FlowToken_bad.totalSupply = FlowToken_bad.totalSupply - self.balance
            }
        }
    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    pub fun createEmptyVault(): @FungibleToken.Vault {
        return <-create Vault(balance: 0.0)
    }

    pub resource Administrator {
        // createNewMinter
        //
        // Function that creates and returns a new minter resource
        //
        pub fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        // createNewBurner
        //
        // Function that creates and returns a new burner resource
        //
        pub fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    // Minter
    //
    // Resource object that token admin accounts can hold to mint new tokens.
    //
    pub resource Minter {

        // the amount of tokens that the minter is allowed to mint
        pub var allowedAmount: UFix64

        // mintTokens
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context.
        //
        pub fun mintTokens(amount: UFix64): @FlowToken_bad.Vault {
            pre {
                amount > UFix64(0): "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            FlowToken_bad.totalSupply = FlowToken_bad.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    // Burner
    //
    // Resource object that token admin accounts can hold to burn tokens.
    //
    pub resource Burner {

        // burnTokens
        //
        // Function that destroys a Vault instance, effectively burning the tokens.
        //
        // Note: the burned tokens are automatically subtracted from the
        // total supply in the Vault destructor.
        //
        pub fun burnTokens(from: @FungibleToken.Vault) {
            let vault: @FlowToken_bad.Vault <- from as! @FlowToken_bad.Vault
            let amount: UFix64 = vault.balance
            destroy (vault)
            emit TokensBurned(amount: amount)
        }
    }

    init() {
        self.totalSupply = 0.0
        self.devMode = true

        self.vaultStorage = /storage/badFlowTokenVault
        self.adminStorage = /storage/badFlowTokenAdmin
        self.vaultBalancePublic = /public/badFlowTokenBalance
        self.vaultReceiverPublic = /public/badFlowTokenReceiver

        if (self.devMode) {
            let randomVault: @AnyResource <- self.account.load<@AnyResource>(from: self.vaultStorage)
            destroy (randomVault)

            let randomAdmin: @AnyResource <- self.account.load<@AnyResource>(from: self.adminStorage)
            destroy (randomAdmin)

            self.account.unlink(self.vaultReceiverPublic)
            self.account.unlink(self.vaultBalancePublic)
        }

        let vault: @FlowToken_bad.Vault <- create Vault(balance: self.totalSupply)
        self.account.save(<- vault, to: self.vaultStorage)

        self.account.link<&FlowToken_bad.Vault{FungibleToken.Receiver}>(self.vaultReceiverPublic, target: self.vaultStorage)

        self.account.link<&FlowToken_bad.Vault{FungibleToken.Balance}>(self.vaultBalancePublic, target: self.vaultStorage)

        let admin: @FlowToken_bad.Administrator <- create Administrator()
        self.account.save(<- admin, to: self.adminStorage)

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}
 
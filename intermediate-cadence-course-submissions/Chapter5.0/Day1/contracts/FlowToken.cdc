/*
    By some reason, I'm unable to deploy the original FlowToken contract and for a bullshit reason: it keeps failing saying that the deployer account doesn't have
    enough storage space left and the account needs more FLOW to increase it, which is absurd because, in the emulator, the emulator-account in which I'm trying to
    deploy this piece of shit contract has a ridiculous amount of (fake) FLOW in it, like 100k or something!
    The problem seems to be in the space calculation for the account to deploy the FlowToken.cdc contract, which by whatever reason comes up always as 0!, which
    doesn't make any sense. I'm running out of options, so I'm going to create a contract that is functionally identical just to see what happens...
*/

import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"

// Mainnet
// import FungibleToken from 0xf233dcee88fe0abe

// Testnet
// import FungibleToken from 0x9a0766d93b6608b7

pub contract FlowToken: FungibleToken {
    pub var totalSupply: UFix64
    pub event TokensInitialized(initialSupply: UFix64)
    pub event TokensWithdrawn(amount: UFix64, from: Address?)
    pub event TokensDeposited(amount: UFix64, to: Address?)
    pub event TokensMinted(amount: UFix64)
    pub event TokensBurned(amount: UFix64)
    pub event MinterCreated(allowedAmount: UFix64)
    pub event BurnerCreated()

    pub let devMode: Bool

    pub let vaultStorage: StoragePath
    pub let adminStorage: StoragePath
    pub let vaultBalancePublic: PublicPath
    pub let vaultReceiverPublic: PublicPath

    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {
        pub var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance
        }

        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <- create Vault(balance: amount)
        }

        pub fun deposit(from: @FungibleToken.Vault) {
            let vault: @FlowToken.Vault <- from as! @FlowToken.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            if (self.balance > 0.0 ) {
                FlowToken.totalSupply = FlowToken.totalSupply - self.balance
            }
        }
    }

    pub fun createEmptyVault(): @FungibleToken.Vault {
        return <- create Vault(balance: 0.0)
    }

    pub resource Minter {
        pub var allowedAmount: UFix64

        pub fun mintTokens(amount: UFix64): @FlowToken.Vault {
            pre {
                amount > UFix64(0): "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            FlowToken.totalSupply = FlowToken.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <- create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    pub resource Burner {
        pub fun burnTokens(from: @FungibleToken.Vault) {
            let vault: @FlowToken.Vault <- from as! @FlowToken.Vault
            let amount: UFix64 = vault.balance
            destroy vault
            emit TokensBurned(amount: amount)
        }
    }

    pub resource Administrator {
        pub fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <- create Minter(allowedAmount: allowedAmount)
        }

        pub fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <- create Burner()
        }
    }

    init() {
        self.totalSupply = 0.0
        self.devMode = true

        self.vaultStorage = /storage/FlowTokenVault
        self.adminStorage = /storage/FlowTokenAdmin
        self.vaultBalancePublic = /public/FlowTokenBalance
        self.vaultReceiverPublic = /public/FlowTokenReceiver

        if (self.devMode) {
            let randomVault: @AnyResource <- self.account.load<@AnyResource>(from: self.vaultStorage)
            destroy randomVault

            let randomAdmin: @AnyResource <- self.account.load<@AnyResource>(from: self.adminStorage)
            destroy randomAdmin

            self.account.unlink(self.vaultReceiverPublic)
            self.account.unlink(self.vaultBalancePublic)
        }

        let vault: @FlowToken.Vault <- create Vault(balance: self.totalSupply)
        self.account.save(<- vault, to: self.vaultStorage)

        self.account.link<&FlowToken.Vault{FungibleToken.Receiver}>(self.vaultReceiverPublic, target: self.vaultStorage)

        self.account.link<&FlowToken.Vault{FungibleToken.Balance}>(self.vaultBalancePublic, target: self.vaultStorage)

        let admin: @FlowToken.Administrator <- create Administrator()
        self.account.save(<- admin, to: self.adminStorage)

        emit TokensInitialized(initialSupply: self.totalSupply)

        /*
            Apparently, removing all the comments fixed the issues with
        */
    }
}
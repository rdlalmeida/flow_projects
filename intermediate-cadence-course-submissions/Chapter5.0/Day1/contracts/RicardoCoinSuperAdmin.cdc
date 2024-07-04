import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"

// import FungibleToken from 0xf233dcee88fe0abe        // Mainnet
// import FungibleToken from 0x9a0766d93b6608b7        // Testnet

/*
    This version of the RicardoCoin contract allows the Admin to withdraw RicardoCoin tokens from a user's account and replace those with
    FlowTokens. To be able to test this, I've modified the FlowToken.cdc contract to be deployable in the same account as this one and allowed this
    Administrator token to mint FlowTokens ($FLOW) at will, which obviously doesn't work on a mainnet scenario.
*/

pub contract RicardoCoinSuperAdmin: FungibleToken {

    // Total number of Ricardo Coins in existence
    pub var totalSupply: UFix64

    // Event emitted when the contract is initialized
    pub event TokensInitialized(initialSupply: UFix64)

    // Event emitted when RicardoCoins are withdraw from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    // Event emitted when RicardoCoins are deposited into a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    // Event emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    // Event emitted when tokens are destroyed with a Burner Resource
    pub event TokensBurned(amount: UFix64)

    // Event emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64)

    // Event emitted when a new Burner reource is created
    pub event BurnerCreated()

    // Various storage and public paths
    pub let vaultStorage: StoragePath
    pub let adminStorage: StoragePath

    // Path to link the main contract Vault to the Public Storage for deposit purposes
    pub let vaultReceiverPublic: PublicPath

    // Path to link the main contract Vault to the Public Storage for consultation purposes
    pub let vaultBalancePublic: PublicPath

    // Simple flag to deal to issues due to this contract needed to be updated to correct bugs
    pub let devMode: Bool

    // Path to link the Interface that allows the Administrator to withdraw tokens from a user's account
    pub let adminAccessVaultPublic: PublicPath

    /*
        To enable the Administrator resource to withdraw RicardoCoin tokens from a user's account, I need to do a bunch of things first:
            1. Define an Interface to add to this Vault's Resource definition that exposes another withdraw function.
                1.a) Simply exposing the FungibleToken.Provider interface when linking the user's account publicly is a bad idea. This allows random user's to
                    withdraw tokens from their accounts at will.
                1.b) Changing the access of the withdraw function in the Vault Resource to, let's say, access(account), limits the access to this function to only
                    the administrator. Another bad idea because that prevents the user's from withdrawing tokens from their account (because of the new access rights),
                    and also violates the FungibleToken.Provider interface, so I would need to change this interface to achieve this, which is another No-No.
            2. Define a new but functionally similar withdraw function and set it with access(account) control to limit its usage to the Administrator
            3. Add this new Interface to the Vault resource definition and set up the new user's Vault with this one linked too.
    */
    pub resource interface AdminVaultAccess{
        access(account) fun adminWithdraw(amount: UFix64): @FungibleToken.Vault

        /*
            I'm adding the deposit function to this interface because the point with this is to enable the withdraw of RicardoCoinSuperAdmin tokens and
            replace these for $FLOW tokens. This way I need only a sigle reference to a Vault that implements this Interface and not another one just to
            access the deposit function (alteratively, I could just add this new function to the FungibleToken.Receiver interface, but I don't want to 
            mess around with this one)
        */
        pub fun deposit(from: @FungibleToken.Vault)
    }

    /* 
        Vault resource

        Like as with many other examples, users will use this Resource to hold Ricardo
        Coins in their accounts. Deposits and withdraws are pre regulated by the pre and
        post conditions inherited from the FungibleToken interfaces.

        The minting of new RicardoCoins is regulated by an Admin Resource (as is often the
        case), via a Minter resource, whose usage is limited to the deployer of this contract    
    */
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance, AdminVaultAccess {
        // Variable to keep track the number of RicardoCoins in each account/Vault
        pub var balance: UFix64

        /*
            When a new Vault in initialized, it can be set to a certain value. This may seem unwise,
            but the Withdraw and Deposit functions to be set next use "temporary" Vaults to transfer
            RicardoCoins around and therefore this ability is needed. In any case, the creation of new
            Vaults can only be done with a dedicated function and that one ensures that the initial
            balance for new Vaults are always 0.0.
        */

        init(balance: UFix64) {
            self.balance = balance
        }

        /*
            Special Withdraw function that as admin access rights, which, hopefully, means that only the Administrator (or more specifically the contract deployer)
            can use it. Otherwise this pretty much invalidates this contract...
        */
        access(account) fun adminWithdraw(amount: UFix64): @FungibleToken.Vault {
            // Functionally, this function is identical to the other one, because the objective is the same. The only major change is the access permissions to the
            // function that ensures that only an Administator can do this
            pre {
                self.balance >= amount: "This Vault does not has enough balance for that operation!"
            }

            self.balance = self.balance - amount

            emit TokensWithdrawn(amount: amount, from: self.owner?.address)

            return <- create Vault(balance: amount)
        }

        /*
            Withdraw

            This function extracts a UFix64 quantity of RicardoCoins via a temporary Vault,
            which then can be (should) be used somewhere, namely, deposited
        */
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            pre {
                // Make sure enough balance exists before attempting anything else
                self.balance >= amount: "This Vault does not has enough balance for that operation!"
            }
            // Subtract the amount to the Vault balance
            self.balance = self.balance - amount

            // Emit the relevant Event
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            
            // Return a Vault resource with the withdraw balance
            return <- create Vault(balance: amount)
        }

        /*
            Deposit

            This function takes an incoming Vault, with some balance associated to it, 
            and adds it to the current Vault balance.
            After adding the incoming balance to this own, the "empty" Vault needs to
            be destroyed, because Resouces need to go somewhere at the end of a function
            execution
        */
        pub fun deposit(from: @FungibleToken.Vault) {
            // Cast the incoming Vault to the proper type
            let inVault: @RicardoCoinSuperAdmin.Vault <- from as! @RicardoCoinSuperAdmin.Vault
            
            // Update the balance
            self.balance = self.balance + inVault.balance

            // Emit the relevant Event
            emit TokensDeposited(amount: inVault.balance, to: self.owner?.address)

            // The balance was adjusted. Set the incoming Vault balance to 0.0 before destroying
            // the Vault or otherwise these are going to be subtracted from the contract's totalSupply,
            // wich is going to create imbalances because these coins are now in this Vault.
            inVault.balance = 0.0

            // Destroy the incoming Vault resource
            destroy inVault
        }

        // Define the rules for the destroy function for this function, which needs special care
        destroy() {
            // If the Vault being destroyed has some RicardoCoins still in it for whatever reason
            if (self.balance > 0.0) {
                // Subtract the tokens that are going to be destroyed from the total supply to keep
                // the total balance of RicardoCoins out there correct.
                RicardoCoinSuperAdmin.totalSupply = RicardoCoinSuperAdmin.totalSupply - self.balance
            }
        }

    }

    /*
        createEmptyVault

        This function is the only way to create a Vault to hold RicardoCoins externally,
        therefore any Vault created this way is set with its balance to 0.0.
        Users need a valid Vault set in their account before being able to trade
        RicardoCoins around
    */
    pub fun createEmptyVault(): @FungibleToken.Vault {
        // Create and return a Vault with balance set to 0.0
        return <- create Vault(balance: 0.0)
    }

    /*
        Administrator

        A Administrator resource that is to be created, stored and only linked to the private
        storage. This Resource is the only one able to create Minter Resources, which
        are the only ones that can mint new RicardoCoin tokens. Yet, this value is set as a
        var, so it can be changed after creation. But since everytime a Minter creates new
        tokens, these are added to the total amount, so everything is always accounted for.

        This Administrator now has the ability to withdraw tokens from a user's Vault by invoking
        a new function that is only accessible to it
    */
    pub resource Administrator {
        /*
            createNewMinter

            Function to create a new Minter resource
        */
        pub fun createNewMinter(allowedAmount: UFix64): @RicardoCoinSuperAdmin.Minter {
            // Emit the relevant event
            emit MinterCreated(allowedAmount: allowedAmount)

            // Create and return a Minter resource
            return <- create Minter(allowedAmount: allowedAmount)
        }

        /*
            createNewBurner

            Similar function as above but to create the Burner resource
        */
        pub fun createNewBurner(): @Burner {
            // Emit the event to start
            emit BurnerCreated()

            // Create and return a Burner resource
            return <- create Burner()
        }

        /*
            This function executes the access(account) limited function that enables the withdraw of RicardoCoinSuperAdmin tokens and its replacement
            with $FLOW tokens
        */
        pub fun withdrawTokensFromAccount(amount: UFix64, vaultRef: &RicardoCoinSuperAdmin.Vault{RicardoCoinSuperAdmin.AdminVaultAccess}): Void {
            // Withdraw the RicardoCoinSuperAdmin tokens and deposit them in this contract's deployer's Vault
            let adminVaultRef: &RicardoCoinSuperAdmin.Vault{FungibleToken.Receiver} 
                = RicardoCoinSuperAdmin.account.getCapability<&RicardoCoinSuperAdmin.Vault{FungibleToken.Receiver}>(RicardoCoinSuperAdmin.vaultReceiverPublic).borrow() ??
                    panic("Unable to retrieve a reference for RicardoCoinSuperAdmin.Vault{FungibleToken.Receiver} from ".concat(RicardoCoinSuperAdmin.account.address.toString()))

            adminVaultRef.deposit(from: <- vaultRef.adminWithdraw(amount: amount))

            // Create a minter and mint the same amount of $FLOW tokens into the user's account
            let minter: @Minter <- self.createNewMinter(allowedAmount: amount)
            vaultRef.deposit(from: <- minter.mintTokens(amount: amount))

            // Destroy the spent minter
            destroy minter
        }
    }

    /* 
        Minter

        The resource used to create new RicardoCoin tokens.
        This minter follows the same logic in FlowToken: to keep some flexibility,
        Minters can be created at will by the Admin resource. But to keep some
        "regulation" regarding the minting of new RicardoCoin tokens, each Minter
        comes limited to a max amount of tokens that it can mint.
    */
    pub resource Minter {
        // The amount of tokens that are allowed to be mint
        pub var allowedAmount: UFix64

        /*
            mintTokens

            The function that creates new token, creating them inside a Vault,
            as the usual vessel used for these porposes. Each mint updates the
            total amount of tokens set at the contract level
        */
        pub fun mintTokens(amount: UFix64): @RicardoCoinSuperAdmin.Vault {
            pre{
                amount > UFix64(0): "Amount of RicardoCoin to mint must be greater than 0!"
                amount <= self.allowedAmount: "This Minter can only mint up to "
                    .concat(self.allowedAmount.toString())
                    .concat(" tokens so far. Unable to mint more than this value.")
            }
            // Update the total supply of the contract
            RicardoCoinSuperAdmin.totalSupply = RicardoCoinSuperAdmin.totalSupply + amount

            // Update the allowed amount in the Minter
            self.allowedAmount = self.allowedAmount - amount

            // Emit the relevant Event
            emit TokensMinted(amount: amount)

            // Return a new Vault with the balance = amount minted. This is how the
            // new tokens are really created
            return <- create RicardoCoinSuperAdmin.Vault(balance: amount)
        }

        // Initialize the Minter resource by setting the allowed amount
        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    /*
        Burner

        Resource used to destroy tokens, for whatever reason
    */
    pub resource Burner {
        /*
            burnTokens

            This function that destroy a Vault instance. Tokens destroyed this way
            are naturally subtrated to the totalAmount to keep the ecosystem stable
        */
        pub fun burnTokens(from: @FungibleToken.Vault) {
            // Cast the incoming Vault to the proper type
            let vault: @RicardoCoinSuperAdmin.Vault <- from as! @RicardoCoinSuperAdmin.Vault

            // Take note of the amount to burn for the event later on
            let amount: UFix64 = vault.balance

            // Destroy the Vault resource
            destroy vault

            // Emit the related event
            emit TokensBurned(amount: amount)
        }

    }

    init () {
        // Set the development mode on or off
        self.devMode = true

        // Jump start the contract with totalSupply = 0.0
        self.totalSupply = 0.0

        // Define the paths
        self.vaultStorage = /storage/SuperRicardoVault
        self.adminStorage = /storage/SuperRicardoAdmin

        self.vaultReceiverPublic = /public/SuperRicardoVaultReceiver
        self.vaultBalancePublic = /public/SuperRicardoVaultBalance
        self.adminAccessVaultPublic = /public/adminAccessVault

        if (self.devMode) {
            // If the devMode is ON, destroy and unlink any existing Vaults and Administrators in the Storage accounts
            // to account for changes in the main contract that may affect these resources
            let randomVault: @AnyResource <- self.account.load<@AnyResource>(from: self.vaultStorage)
            destroy randomVault

            let randomAdmin: @AnyResource <- self.account.load<@AnyResource>(from: self.adminStorage)
            destroy randomAdmin

            self.account.unlink(self.vaultBalancePublic)
            self.account.unlink(self.vaultReceiverPublic)
        }

        // Create the main Vault for the contract, like the bank for all RicardoCoin tokens... of sorts
        let mainVault: @RicardoCoinSuperAdmin.Vault <- create RicardoCoinSuperAdmin.Vault(balance: self.totalSupply)

        // Save them to the contract deployer's account
        self.account.save(<- mainVault, to: self.vaultStorage)

        // Link the Receiver 'part' of the main Vault and the Balance 'part' to the Public Storage
        self.account.link<&RicardoCoinSuperAdmin.Vault{FungibleToken.Receiver}>(self.vaultReceiverPublic, target: self.vaultStorage)
        self.account.link<&RicardoCoinSuperAdmin.Vault{FungibleToken.Balance}>(self.vaultBalancePublic, target: self.vaultStorage)

        // Create and save an Administrator Resource. This is the only time this is going to happen
        let ricardoAdmin: @RicardoCoinSuperAdmin.Administrator <- create RicardoCoinSuperAdmin.Administrator()
        self.account.save(<- ricardoAdmin, to: self.adminStorage)

        // All done. Emit the event that signals that the contract was properly initialzed
        emit TokensInitialized(initialSupply: self.totalSupply)
        
    }
}
 
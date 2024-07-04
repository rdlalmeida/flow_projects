// ExampleToken.cdc
//
// The ExampleToken contract is a sample implementation of a fungible token on Flow.
//
// Fungible tokens behave like everyday currencies -- they can be minted, transferred or
// traded for digital goods.
//
// Follow the fungible tokens tutorial to learn more: https://docs.onflow.org/docs/fungible-tokens
//
// This is a basic implementation of a Fungible Token and is NOT meant to be used in production
// See the Flow Fungible Token standard for real examples: https://github.com/onflow/flow-ft

pub contract ExampleToken {

    // Total supply of all tokens in existence
    pub var totalSupply: UFix64

    pub let VaultStoragePath: StoragePath
    pub let VaultPublicPath: PublicPath
    pub let VaultPrivatePath: PrivatePath

    pub let BalanceStoragePath: StoragePath
    pub let BalancePublicPath: PublicPath

    pub let AdminStoragePath: StoragePath
    pub let AdminPublicPath: PublicPath

    pub let VaultMinterStoragePath: StoragePath
    pub let VaultMinterPublicPath: PublicPath
    pub let VaultMinterPrivatePath: PrivatePath

    pub event TokensMinted(amount: UFix64, recipientAddress: Address)


    // Provider
    //
    // Interface that enforces the requirements for withdrawing
    // tokens from the implementing type.
    //
    // We don't enforce requirements on self.balance here because
    // it leaves open the possibility of creating custom providers
    // that don't necessarily need their own balance.
    //
    pub resource interface Provider {

        // withdraw
        //
        // Function that subtracts tokens from the owner's Vault
        // and returns a Vault resource (@Vault) with the removed tokens.
        //
        // The function's access level is public, but this isn't a problem
        // because even the public functions are not fully public at first.
        // anyone in the network can call them, but only if the owner grants
        // them access by publishing a resource that exposes the withdraw
        // function.
        //
        pub fun withdraw(amount: UFix64): @Vault {
            post {
                // `result` refers to the return value of the function
                result.balance == UFix64(amount):
                    "Withdrawal amount must be the same as the balance of the withdrawn Vault"
            }
        }
    }

    // Receiver
    //
    // Interface that enforces the requirements for depositing
    // tokens into the implementing type.
    //
    // We don't include a condition that checks the balance because
    // we want to give users the ability to make custom Receivers that
    // can do custom things with the tokens, like split them up and
    // send them to different places.
    //
	pub resource interface Receiver {
        // deposit
        //
        // Function that can be called to deposit tokens
        // into the implementing resource type
        //
        pub fun deposit(from: @Vault) {
            pre {
                from.balance > 0.0:
                    "Deposit balance must be positive"
            }
        }
    }

    // Balance
    //
    // Interface that specifies a public `balance` field for the vault
    //
    pub resource interface Balance {
        pub var balance: UFix64

        pub fun getBalance(): UFix64
    }

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in the interfaces when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special Minter resource needs to be defined to mint
    // new tokens.
    //
    pub resource Vault: Provider, Receiver, Balance {

		// keeps track of the total balance of the account's tokens
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        // withdraw
        //
        // Function that takes an integer amount as an argument
        // and withdraws that amount from the Vault.
        //
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @Vault {
            pre {
                amount <= self.balance: "This account (".concat((self.owner!).address.toString()).concat(") does not have enough funds for this operation!")
            }

            self.balance = self.balance - amount
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        //
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the tokens. The Vault's balance has
        // been consumed and therefore can be destroyed.
        pub fun deposit(from: @Vault) {
            self.balance = self.balance + from.balance
            destroy from
        }

        pub fun getBalance(): UFix64 {
            return self.balance
        }
    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this token type.
    //
    pub fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }

	// VaultMinter
    //
    // Resource object that an admin can control to mint new tokens
    pub resource VaultMinter {

		// Function that mints new tokens and deposits into an account's vault
		// using their `Receiver` reference.
        // We say `&AnyResource{Receiver}` to say that the recipient can be any resource
        // as long as it implements the Receiver interface
        pub fun mintTokens(amount: UFix64, recipient: Capability<&AnyResource{Receiver}>) {
            let recipientRef = recipient.borrow()
                ?? panic("Could not borrow a receiver reference to the vault")

            ExampleToken.totalSupply = ExampleToken.totalSupply - amount
            recipientRef.deposit(from: <-create Vault(balance: amount))

            // Emit the related event
            emit TokensMinted(amount: amount, recipientAddress: recipient.address)
        }
    }

    // The init function for the contract. All fields in the contract must
    // be initialized at deployment. This is just an example of what
    // an implementation could dExampleToken.VaultPublicPath in the init function. The numbers are arbitrary.
    init() {
        self.VaultStoragePath = /storage/VaultStoragePath
        self.VaultPublicPath = /public/VaultStoragePath
        self.VaultPrivatePath = /private/VaultStoragePath

        self.BalanceStoragePath = /storage/BalanceStoragePath
        self.BalancePublicPath = /public/BalanceStoragePath

        self.AdminStoragePath = /storage/AdminStoragePath
        self.AdminPublicPath = /public/AdminStoragePath

        self.VaultMinterStoragePath = /storage/VaultMinterStoragePath
        self.VaultMinterPublicPath = /public/VaultMinterStoragePath
        self.VaultMinterPrivatePath = /private/VaultMinterStoragePath


        self.totalSupply = 3000.0

        // create the Vault with the initial balance and put it in storage
        // account.save saves an object to the specified `to` path
        // The path is a literal path that consists of a domain and identifier
        // The domain must be `storage`, `private`, or `public`
        // the identifier can be any name
        let vault <- create Vault(balance: self.totalSupply)

        // Clean up the resource storage before attempting to save the vault resource
        let randomVault: @AnyResource <- self.account.load<@AnyResource>(from: self.VaultStoragePath)

        if (randomVault == nil) {
            // Nothing was found in the storage path. Destroy the nil resource captured and move on
            destroy randomVault
        }
        else {
            // Log the Resource type retrieved and destroy it before moving on
            log(
                "Retrieved a '"
                .concat(randomVault.getType().identifier)
                .concat("' resource from Storage. Destroying it...")
            )

            destroy randomVault
        }

        // Now that I've ensured that the storage area is free, save the thing then
        self.account.save(<- vault, to: self.VaultStoragePath)
        
        //self.account.save(<-vault, to: /storage/CadenceFungibleTokenTutorialVault)

        // Repeat the storage cleanse process than before
        let randomMinter:@AnyResource <- self.account.load<@AnyResource>(from: self.VaultMinterStoragePath)

        if (randomMinter == nil) {
            // Nothing. Destroy it
            destroy randomMinter
        }
        else {
            // Log the thing
            log(
                "Retrieved a '"
                .concat(randomMinter.getType().identifier)
                .concat("' resource from storage. Destroying it...")
            )

            destroy randomMinter
        }
        
        // Create a new MintAndBurn resource and store it in account storage
        self.account.save(<- create VaultMinter(), to: /storage/VaultMinterStoragePath)

        let mintingRef = self.account.borrow<&ExampleToken.VaultMinter>(from: /storage/VaultMinterStoragePath) ?? panic("Could not borrow a reference to the minter")
        
        log("Got the damn reference right!")
        // self.account.save(<-create VaultMinter(), to: /storage/CadenceFungibleTokenTutorialMinter)

        // Create a private capability link for the Minter
        // Capabilities can be used to create temporary references to an object
        // so that callers can use the reference to access fields and functions
        // of the objet.
        //
        // The capability is stored in the /private/ domain, which is only
        // accesible by the owner of the account
        // self.account.link<&VaultMinter>(/private/Minter, target: /storage/CadenceFungibleTokenTutorialMinter)
        // self.account.link<&VaultMinter>(self.VaultMinterPrivatePath, target: self.VaultMinterStoragePath)
    }
}
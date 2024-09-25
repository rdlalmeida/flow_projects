import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"
import RicardoCoin from "../contracts/RicardoCoin.cdc"
import FlowToken from "../contracts/FlowToken.cdc"

// Testnet addresses
// import FungibleToken from 0x9a0766d93b6608b7
// import RicardoCoin from 0xb7fb1e0ae6485cf6
// import FlowToken from 0xb7fb1e0ae6485cf6

// Contract that allows a user to deposit $FLOW tokens into an admin account and receive
// 2*(Time since they last swapped)
pub contract Swap{
    // To achieve the date since the user last swapped tokens, I need to keep a record of every swaps in this contracts, so I'm going 
    // to keep a dictionary that links an address to a timestap to keep track of this
    pub var userSwaps: {Address: UFix64}

    // Setup some paths for consistency
    pub let swapperStorage: StoragePath
    pub let swapperPublic: PublicPath

    // Set of Events given that I'm going to test this in Testnet and I don't have access to logs
    // Emit this one when this contract is initialized
    pub event SwapContractInitialized()

    // Emit this one when a new Swapper resource is creted
    pub event SwapperIdentityCreated()

    // Emit this one when a successful swap has occurred
    pub event TokensSwappedSuccessfully(flowDeposited: UFix64, tokensReceived: UFix64, address: Address)

    // To ensure the identity of the swapper, I'm going to encode the swapping function in a Resource that needs to be
    // created and publicly linked to be used first
    pub resource SwapperIdentity {
        // The main swapping function. Assumes, obviously, that the custom token contract is deployed in this contract's deployer account
        // Otherwise its impossible to mint custom tokens.
        pub fun swap(flowVault: @FlowToken.Vault) {
            // Get a reference to the Vault to deposit the FlowTokens
            let adminFlowVaultRef: &FlowToken.Vault{FungibleToken.Receiver} 
                = Swap.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(FlowToken.vaultReceiverPublic).borrow() ??
                    panic("Unable to borrow a FlowToken.Vault{FungibleToken.Receiver} reference from admin account ".concat(Swap.account.address.toString()))
            
            // Get the minter through a reference to the Admin in the custom token contract account
            let ricardoAdminRef: &RicardoCoin.Administrator = Swap.account.borrow<&RicardoCoin.Administrator>(from: RicardoCoin.adminStorage) ??
                panic("Unable to retrieve an Administrator reference for a RicardoCoin.Administrator from admin account ".concat(Swap.account.address.toString()))
            
            // Get a reference to the user's custom Vault. This one ensures that this function is being called from a signed transaction. Otherwise this next
            // instruction is going to abort the rest of the function. For clarity sake, I'm splitting this action in two
            if let user:PublicAccount = self.owner {
                // This one checks if the function is being properly called from a transaction and using a reference for a stored SwapperIdentity resource
                // If the if happens, all is good
            }
            else {
                // Otherwise, the function is not being properly called
                panic("Unable to validate a user for this call. Please use a Public Reference for a stored SwapperIdentity Resource to continue")
            }

            let userRicardoVaultRef: &RicardoCoin.Vault{FungibleToken.Receiver} 
                = self.owner!.getCapability<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic).borrow() ??
                    panic("Unable to get a RicardoCoin.Vault receiver reference for user ".concat(self.owner!.address.toString()))

            // Calculate the amount of custom tokens to return to the user. If this is the first swap, the rate is just 2x
            let lastAccess: UFix64? = Swap.userSwaps[self.owner!.address]

            var multiplier: UFix64? = nil

            if (lastAccess == nil) {
                multiplier = 2.0
            }
            else {
                // Calculate the time difference since the last swap rouded up to the minute to avoid ridiculous returns but small enough to test this
                multiplier = 2.0*((getCurrentBlock().timestamp - lastAccess!)/60.0)
            }

            // Reset the user access
            Swap.userSwaps[self.owner!.address] = getCurrentBlock().timestamp

            let amountToReward: UFix64 = flowVault.balance*(multiplier!)
            let flowReceived: UFix64 = flowVault.balance

            // Create the minter from the admin account with the allowed mount equal to the calculated resource
            let minter: @RicardoCoin.Minter <- ricardoAdminRef.createNewMinter(allowedAmount: amountToReward)

            // I have all I need to execute the swap. Do it
            // Deposit the incoming Vault to the admin Vault
            adminFlowVaultRef.deposit(from: <- flowVault)

            // Mint the custom tokens
            let outgoingVault: @RicardoCoin.Vault <- minter.mintTokens(amount: minter.allowedAmount)

            // Done with the minter. Get rid of it
            destroy minter

            // Deposit the reward into the user's custom token Vault
            userRicardoVaultRef.deposit(from: <- outgoingVault)

            emit TokensSwappedSuccessfully(flowDeposited: flowReceived, tokensReceived: amountToReward, address: self.owner!.address)
        }
    }

    /*
        This swap function, which sits outside of the Identity resource, implements the other version of the swap function that bypasses the usage of the Identity
        resource. This function receives a reference to the user's FlowVault and uses a dedicated function to extract the address from the type of it
        input:  incomingVault: @FlowToken.Vault - The vault to use for the swap process
                vaultRef: &FlowToken.Vault - A reference for a Vault that should be saved into storage that is going to be used to get the owner's Address.
        output: Void -  If the operation is successful, the required event are going to be emited and that's pretty much it
    */
    pub fun swap(incomingVault: @FlowToken.Vault, vaultRef: &FlowToken.Vault) {
        // The rest of this function is similar to the previous one, minus the need of running it from a stored Identity resource
        // Get a reference to the Vault where the incoming tokens are to be deposited
        let adminFlowVaultRef: &FlowToken.Vault{FungibleToken.Receiver}
            = Swap.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(FlowToken.vaultReceiverPublic).borrow() ??
                panic("Unable to retrieve a FlowToken.Vault{FungibleToken.Receiver} reference for the admin account ".concat(Swap.account.address.toString()))

        // Get the minter through a refence to the Admin in the custom token contract account
        let ricardoAdminRef: &RicardoCoin.Administrator = Swap.account.borrow<&RicardoCoin.Administrator>(from: RicardoCoin.adminStorage) ??
            panic("Unable to retrieve an Administrator reference for a RicardoCoin.Administrator from admin account ".concat(Swap.account.address.toString()))

        // Validate the user by checking if the provided vault reference has a valid owner associated to it
        if let user: PublicAccount = vaultRef.owner {
            // If the code gets here, it's all good, I got a valid owner from a properly created reference
        }
        else {
            // Otherwise, panic
            panic("Unable to validate a user for this call. Please provide a reference to a FlowToken.Vault properly saved into a storage account to continue!")
        }

        // Carry on. The user is valid
        let userRicardoVaultRef: &RicardoCoin.Vault{FungibleToken.Receiver} = vaultRef.owner!.getCapability<&RicardoCoin.Vault{FungibleToken.Receiver}>(RicardoCoin.vaultReceiverPublic).borrow() ??
            panic("Unable to get a RicardoCoin.Vault receiver reference for user ".concat(vaultRef.owner!.address.toString()))
        
        // Calculate the amount of custom tokens to return to the user.
        let lastAccess: UFix64? = Swap.userSwaps[vaultRef.owner!.address]

        var multiplier: UFix64? = nil

        if (lastAccess == nil) {
            multiplier = 2.0
        }
        else {
            // Adjust the multiplier to the minute
            multiplier = 2.0*((getCurrentBlock().timestamp - lastAccess!)/60.0)
        }

        // Reset the user access
        Swap.userSwaps[vaultRef.owner!.address] = getCurrentBlock().timestamp

        let amountToReward: UFix64 = incomingVault.balance*(multiplier!)
        let flowReceived: UFix64 = incomingVault.balance

        // Create the minter to produce the reward tokens
        let minter: @RicardoCoin.Minter <- ricardoAdminRef.createNewMinter(allowedAmount: amountToReward)

        // Execute the swap
        adminFlowVaultRef.deposit(from: <- incomingVault)

        // Mint the reward tokens
        let rewardVault: @RicardoCoin.Vault <- minter.mintTokens(amount: minter.allowedAmount)

        // Done with the minter. Destroy it
        destroy minter

        // Deposit the reward into the user's custom token Vault
        userRicardoVaultRef.deposit(from: <- rewardVault)

        // Done. Finish this by emiting the corresponding Event
        emit TokensSwappedSuccessfully(flowDeposited: flowReceived, tokensReceived: amountToReward, address: vaultRef.owner!.address)
    }

    // The usual function to create the Swapper resource
    pub fun createSwapperIdentity(): @Swap.SwapperIdentity {
        let newSwapper: @Swap.SwapperIdentity <- create Swap.SwapperIdentity()
        
        emit SwapperIdentityCreated()

        return <- newSwapper
    }

    init() {
        self.userSwaps = {}

        self.swapperStorage = /storage/swapperIdentity
        self.swapperPublic = /public/swapperIdentity

        emit SwapContractInitialized()
    }
}
 
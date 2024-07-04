import ExampleToken from "../../06/contracts/ExampleToken.cdc"
import ExampleNFT from "../../05/contracts/ExampleNFT.cdc"

/*
    The ExampleMarketplace contract is a very basic simple implementation of an NFT ExampleMarketplace on Flow

    This contract allows users to put their NFTs up for sale. Other users can purchase these NFTs with fungible tokens.

    This contract is a leaning tool and is not meant to be used in productions. See the NFTStorefront contract for a generic marketplace
    smart contract that is used by many different projects on the Flow blockchain.
*/

pub contract ExampleMarketplace {
    pub let SaleStoragePath: StoragePath
    pub let SalePublicPath: PublicPath
    pub let SalePrivatePath: PrivatePath

    // Event that is emited when a new NFT is put up for sale
    pub event ForSale(id: UInt64, price: UFix64, owner: Address?)

    // Even that is emitted when the price of an NFT changes
    pub event PriceChanged(id: UInt64, newPrice: UFix64, owner: Address?)

    // Event that is emitted when a token is purchased
    pub event TokenPurchased(id: UInt64, price: UFix64, seller: Address?, buyer: Address?)

    // Event that is emitted when a seller withdraws their NFT from the sale
    pub event SaleCanceled(id: UInt64, seller: Address?)

    // Interface that users will publish for their Sale collection than only exposes the methods that are supposed to be public
    pub resource interface SalePublic {
        pub fun purchase(tokenID: UInt64, recipient: Capability<&AnyResource{ExampleNFT.NFTReceiver}>, buyTokens: @ExampleToken.Vault)
        pub fun idPrice(tokenID: UInt64): UFix64?
        pub fun getIDs(): [UInt64]
        pub fun getNFTs(): {UInt64: UFix64}
    }

    /*
        SaleCollection

        NFT Collection object that allows a user to put their NFT up for sale where others can send fungible tokens to purchase it
    */
    pub resource SaleCollection: SalePublic {
        /// A capability for the owner's collection
        access(self) var ownerCollection: Capability<&ExampleNFT.Collection>

        // Dictionary of the prices for each NFT by ID
        access(self) var prices: {UInt64: UFix64}

        // The fungible token vault of the owner of this sale. When someone buys a token, this resource can deposit tokens into their account.
        access(account) let ownerVault: Capability<&AnyResource{ExampleToken.Receiver}>

        init (ownerCollection: Capability<&ExampleNFT.Collection>, ownerVault: Capability<&ExampleToken.Vault{ExampleToken.Receiver}>) {
            pre {
                // Check that the owner's collection capability is correct
                ownerCollection.check(): "Owner's NFT Collection Capability is invalid!"

                // Check that the fungible token vault capability is correct
                ownerVault.check(): "Owner's Receiver Capability is invalid!"
            }
            self.ownerCollection = ownerCollection
            self.ownerVault = ownerVault
            self.prices = {}
        }

        // cancelSale gives the owner the opportunity to cancel a sale in the collection
        pub fun cancelSale(tokenID: UInt64) {
            // Remove the price
            self.prices.remove(key: tokenID)
            self.prices[tokenID] = nil

            // Nothing needs to be done with the actual token because it is already in the owner's collection
        }

        // listForSale lists an NFT for sale in this collection
        pub fun listForSale(tokenID: UInt64, price: UFix64) {
            pre {
                self.ownerCollection.borrow()!.idExists(id: tokenID): "NFT to be listed does not exist in the owner's collection"
            }

            // Store the price in the price array
            self.prices[tokenID] = price

            emit ForSale(id: tokenID, price: price, owner: self.owner?.address)
        }

        // changePrince changes the price of a token that is currently for sale
        pub fun changePrice(tokenID: UInt64, newPrice: UFix64) {
            self.prices[tokenID] = newPrice

            emit PriceChanged(id: tokenID, newPrice: newPrice, owner: self.owner?.address)
        }

        // Purchase lets a user send tokens to purchase an NFT that is for sale
        pub fun purchase(tokenID: UInt64, recipient: Capability<&AnyResource{ExampleNFT.NFTReceiver}>, buyTokens: @ExampleToken.Vault) {
            pre {
                self.prices[tokenID] != nil: "No token matching this ID for sale!"

                buyTokens.balance >= (self.prices[tokenID] ?? 0.0): "Not enough tokens to buy the NFT!"

                recipient.borrow != nil: "Invalid NFT receiver capability!"
            }

            // Get the value out of the optional
            let price: UFix64 = self.prices[tokenID]!

            self.prices[tokenID] = nil

            let vaultRef: &AnyResource{ExampleToken.Receiver} = self.ownerVault.borrow() ?? panic("Could not borrow reference to owner token vault")

            // Deposit the purchasing tokens into the owners vault
            vaultRef.deposit(from: <- buyTokens)

            // Borrow a reference to the object that the receiver capability links to. We can force-cast the result here because it has already
            // been checked in the pre-conditions
            let receiverReference: &AnyResource{ExampleNFT.NFTReceiver} = recipient.borrow() ?? panic("Unable to borrow a Reference from the Capability!")

            // Deposit the NFT into the buyers collection
            receiverReference.deposit(token: <- self.ownerCollection.borrow()!.withdraw(withdrawID: tokenID))

            emit TokenPurchased(id: tokenID, price: price, seller: self.owner?.address, buyer: receiverReference.owner?.address)
        }

        // idPrice returns the price of a specific token in the sale
        pub fun idPrice(tokenID: UInt64): UFix64? {
            return self.prices[tokenID]
        }

        // getIDs returns an array of token IDs that are for sale
        pub fun getIDs(): [UInt64] {
            return self.prices.keys
        }

        // Function to return the full 'prices' dictionary
        pub fun getNFTs(): {UInt64: UFix64} {
            return self.prices
        } 
    }

    // createCollection returns a new collection resource to the caller
    pub fun createSaleCollection(
        ownerCollection: Capability<&ExampleNFT.Collection>,
        ownerVault: Capability<&ExampleToken.Vault{ExampleToken.Receiver}>
    ): @SaleCollection {
        return <- create SaleCollection(ownerCollection: ownerCollection, ownerVault: ownerVault)
    }

    init() {
        self.SaleStoragePath = /storage/SalePath
        self.SalePublicPath = /public/SalePath
        self.SalePrivatePath = /private/SalePath
    }
}
 
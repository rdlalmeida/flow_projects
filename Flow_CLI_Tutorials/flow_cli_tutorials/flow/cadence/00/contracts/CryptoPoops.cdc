import NonFungibleToken from "./NonFungibleToken.cdc"
pub contract CryptoPoops: NonFungibleToken {
	pub var totalSupply: UInt64

	pub event ContractInitialized()
	pub event Withdraw(id: UInt64, from: Address?)
	pub event Deposit(id: UInt64, to: Address?)

	pub let CollectionStoragePath: StoragePath
	pub let CollectionPublicPath: PublicPath
	pub let CollectionPrivatePath: PrivatePath

	pub let MinterStoragePath: StoragePath
	pub let MinterPublicPath: PublicPath
	pub let MinterPrivatePath: PrivatePath

	pub resource NFT: NonFungibleToken.INFT {
		pub let id: UInt64

		pub let name: String
		pub let favouriteFood: String
		pub let luckyNumber: Int

		init(_name: String, _favouriteFood: String, _luckyNumber: Int) {
			self.id = self.uuid

			self.name = _name
			self.favouriteFood = _favouriteFood
			self.luckyNumber = _luckyNumber
		}
	}

	pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
		pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

		pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
			let nft: @NonFungibleToken.NFT <- self.ownedNFTs.remove(key: withdrawID) 
				?? panic("This NFT does not exist in this Collection.")
			emit Withdraw(id: nft.id, from: self.owner?.address)
			return <- nft
		}

		pub fun deposit(token: @NonFungibleToken.NFT) {
			let nft: @CryptoPoops.NFT <- token as! @NFT
			emit Deposit(id: nft.id, to: self.owner?.address)
			self.ownedNFTs[nft.id] <-! nft
		}

		pub fun getIDs(): [UInt64] {
			return self.ownedNFTs.keys
		}

		pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
			return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
		}

		// Auth version of the borrow function that returns a downcast reference to the
		// local, more specific 'CyptoPoops.NFT' Resource instead of the more generic 'NonFungibleToken.NFT' one
		// NOTE: Apparently I can set the return type for this function to '&CryptoPoops.NFT', as well as to just '&NFT' 
		// but in the implementation, regarding the reference return itself, it needs to be '&NFT'. Functionally I can't
		// detect any differences but this syntax inconsistency may lead to confusion
		// The algorithm works in both cases, so yeah...
		pub fun borrowAuthNFT(id: UInt64): &CryptoPoops.NFT {
			let reference: auth &NonFungibleToken.NFT = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!

		return reference as! &CryptoPoops.NFT
		}

		init() {
			self.ownedNFTs <- {}
		}

		destroy() {
			destroy self.ownedNFTs
		}
	}

	pub fun createEmptyCollection(): @NonFungibleToken.Collection {
		return <- create Collection()
	}

	pub resource Minter {

		pub fun createNFT(name: String, favouriteFood: String, luckyNumber: Int): @NFT {
			return <- create NFT(_name: name, _favouriteFood: favouriteFood, _luckyNumber: luckyNumber)
		}

		pub fun createMinter(): @Minter {
			return <- create Minter()
		}

	}

	init() {
		// Setup the storage paths
		self.CollectionStoragePath = /storage/MyCollection
		self.CollectionPrivatePath = /private/MyCollection
		self.CollectionPublicPath = /public/MyCollection

		self.MinterStoragePath = /storage/MyMinter
		self.MinterPublicPath = /public/MyMinter
		self.MinterPrivatePath = /private/MyMinter

		self.totalSupply = 0
		emit ContractInitialized()
		self.account.save(<- create Minter(), to: self.MinterStoragePath)
	}
}
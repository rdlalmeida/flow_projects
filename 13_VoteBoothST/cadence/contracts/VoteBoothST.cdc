import "NonFungibleToken"
import "Burner"

access(all) contract VoteBoothST: NonFungibleToken {
    // STORAGE PATHS
    access(all) let ballotPrinterAdminStoragePath: StoragePath
    access(all) let ballotPrinterAdminPublicPath: PublicPath
    access(all) let ballotCollectionStoragePath: StoragePath
    access(all) let ballotCollectionPublicPath: PublicPath
    access(all) let voteBoxStoragePath: StoragePath
    access(all) let voteBoxPublicPath: PublicPath

    // CUSTOM EVENTS
    access(all) event NonNilTokenReturned(_tokenType: Type)
    access(all) event BallotMinted(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotSubmitted(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotModified(_ballotId: UInt64, _voterAddress: Address)
    access(all) event BallotBurned(_ballotId: UInt64, _voterAddress: Address)
    access(all) event ContractDataInconsistent(_ballotId: UInt64)

    // CUSTOM VARIABLES
    access(all) let _name: String
    access(all) let _symbol: String
    access(all) let _ballot: String
    access(all) let _location: String
    access(all) let _options: [UInt64]

    access(all) var totalBallotsMinted: UInt64
    access(all) var totalBallotsSubmitted: UInt64

    access(contract) var ballotOwners: {UInt64: Address}
    access(contract) var owners: {Address: UInt64}

// ----------------------------- BALLOT BEGIN ------------------------------------------------------
    access(all) resource Ballot: NonFungibleToken.NFT, Burner.Burnable {
        access(all) let id: UInt64
        access(self) var option: UInt64
        access(all) let ballotOwner: Address

        access(all) view fun getViews(): [Type] {
            return []
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }

        access(contract) fun burnCallback() {
            emit VoteBoothST.BallotBurned(_ballotId: self.id, _voterAddress: self.ballotOwner)
        }

        access(all) view fun saySomething(): String {
            return "Hello from the VoteBoothST.Ballot Resource!"
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create VoteBoothST.VoteBox()
        }


        init(_ballotOwner: Address) {
            self.id = self.uuid
            self.option = 0
            self.ballotOwner = _ballotOwner
        }
    }
// ----------------------------- BALLOT END --------------------------------------------------------

// ----------------------------- VOTE BOX BEGIN ----------------------------------------------------
    access(all) resource VoteBox: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(contract) var supportedTypes: {Type: Bool}

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return self.supportedTypes
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            if (self.supportedTypes[type]!) {
                return true
            }

            return false
        }

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let ballot: @VoteBoothST.Ballot <- token as! @VoteBoothST.Ballot
            let randomResource: @AnyResource? <- self.ownedNFTs[ballot.id] <- ballot

            if (randomResource != nil) {
                emit NonNilTokenReturned(_tokenType: randomResource.getType())
            }

            destroy randomResource
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let ballot: @{NonFungibleToken.NFT} <- self.ownedNFTs.remove(key: withdrawID) ??
            panic(
                "No Ballots with id "
                .concat(withdrawID.toString())
                .concat(" found in storage for account ")
                .concat(self.owner!.address.toString())
            )

            return <- ballot
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create VoteBoothST.VoteBox()
        }

        init() {
            self.ownedNFTs <- {}
            self.supportedTypes = {}
        }
    }
// ----------------------------- VOTE BOX END ------------------------------------------------------

// ----------------------------- BALLOT PRINTER BEGIN ----------------------------------------------
    access(all) resource BallotPrinterAdmin {
        access(all) fun printBallot(voterAddress: Address): @Ballot {
            let newBallot: @Ballot <- create Ballot(_ballotOwner: voterAddress)

            emit BallotMinted(_ballotId: newBallot.id, _voterAddress: voterAddress)

            return <- newBallot
        }

        access(all) fun burnBallot(ballotToBurn: @VoteBoothST.Ballot) {
            Burner.burn(<- ballotToBurn)
        }

        access(all) view fun saySomething(): String {
            return "Hello from inside the VoteBoothST.BallotPrinterAdmin Resource"
        }

        init() {}
    }

    access(self) fun createBallotPrinterAdmin(): @VoteBoothST.BallotPrinterAdmin {
        return <- create VoteBoothST.BallotPrinterAdmin()
    }
// ----------------------------- BALLOT PRINTER END ------------------------------------------------
    
    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create VoteBoothST.VoteBox()
    }

    access(all) view fun saySomething(): String {
        return "Hello from the VoteBoothST.cdc contract level!"
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return []
    }
    
    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        return nil
    }

    init(name: String, symbol: String, ballot: String, location: String, options: String) {
        self.ballotPrinterAdminStoragePath = /storage/BallotPrinterAdmin
        self.ballotPrinterAdminPublicPath = /public/BallotPrinterAdmin
        self.ballotCollectionStoragePath = /storage/BallotCollection
        self.ballotCollectionPublicPath = /public/BallotCollection
        self.voteBoxStoragePath = /storage/VoteBox
        self.voteBoxPublicPath = /public/VoteBox

        self._name = name
        self._symbol = symbol
        self._ballot = ballot
        self._location = location

        // Process the options string into an array
        var newOptions: [UInt64] = []
        var newInt: UInt64? = nil
        let inputOptions: [String] = options.split(separator: ";")

        for option in inputOptions {
            newInt = UInt64.fromString(option)

            if (newInt != nil) {
                newOptions.append(newInt!)
            }
            else {
                panic(
                    "VoteBoothST constructor - Found an invalid option element: "
                    .concat(option)
                )
            }
        }

        self._options = newOptions
        self.totalBallotsMinted = 0
        self.totalBallotsSubmitted = 0
        self.ballotOwners = {}
        self.owners = {}

        // Clean up storage and capabilities
        let randomResource: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.ballotPrinterAdminStoragePath)

        if (randomResource != nil) {
            log(
                "Found a type '"
                .concat(randomResource.getType().identifier)
                .concat("' object in at ")
                .concat(self.ballotPrinterAdminStoragePath.toString())
                .concat(" path in account ")
                .concat(self.account.address.toString())
                .concat(" storage!")
            )
        }

        destroy randomResource

        let oldCap: Capability? = self.account.capabilities.unpublish(self.ballotPrinterAdminPublicPath)

        if (oldCap != nil) {
            log(
                "Found an active capability at "
                .concat(self.ballotPrinterAdminPublicPath.toString())
                .concat(" from account ")
                .concat(self.account.address.toString())
            )
        }

        let anotherResource: @AnyResource? <- self.account.storage.load<@AnyResource>(from: self.ballotCollectionStoragePath)

        if (anotherResource != nil) {
            log(
                "Found a type '"
                .concat(anotherResource.getType().identifier)
                .concat("' object in at ")
                .concat(self.ballotCollectionStoragePath.toString())
                .concat(" path in account ")
                .concat(self.account.address.toString())
                .concat(" storage!")
            )
        }

        destroy anotherResource

        self.account.storage.save(<- create BallotPrinterAdmin(), to: self.ballotPrinterAdminStoragePath)

        let printerCapability: Capability<&VoteBoothST.BallotPrinterAdmin> = self.account.capabilities.storage.issue<&VoteBoothST.BallotPrinterAdmin> (self.ballotPrinterAdminStoragePath)

        self.account.capabilities.publish(printerCapability, at: self.ballotPrinterAdminPublicPath)
    }
}
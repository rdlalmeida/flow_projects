/*
    This is Flow's version of ERC-721 Solidity's standard. When a contract implements an Interface, that contract guarantees that the parameters and functions defined in the Interface exists and can be invoked. The actual implementation of those function is still dependent of whomever writes the contract. This "standard", just like the ERC-721 sandard, only guarantees certain function and parameters presented in the contract's implementation.
*/
import NonFungibleToken from "../../utils/NonFungibleToken.cdc"

access(all) contract FooBar: NonFungibleToken {
    /* 
        Set the neccessary paths for this exercise. The storage ones are accessible only to the contract, though this is not that terrible in terms of privacy, but the public path, because it may be needed for other users and contracts, has complete access.
    */
    access(all) let MinterStoragePath: StoragePath
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath

    // I'm creating this event for the rare possibility of getting a weirdly typed NFT in my Collection
    access(all) event WrongCollectionItem(id: UInt64, tokenType: Type)

    // Next I need to implement the Events in the NonFungibleToken interface as well
    access(all) event ContractInitialized()
    access(all) event Withdraw(id: UInt64, from: Address?)
    access(all) event Deposit(id: UInt64, to: Address?)

    // And the usual totalSupply that is ever presence in NFT definitions
    access(all) var totalSupply: UInt64

    /*
        The main Resource to implement in this contract. Since the NonFungibleToken Interface also implements a standard for the NFT Resources, this contract is also bounded to respect this "sub-interface". This means that NFTs created through this contract have the minimal functionalities and parameters established by the NonFungibleToken.NFT standard.

        NOTE: Consulting the NonFungibleToken.cdc contract, I can verify that the NonFungibleToken.NFT Resource actually implements a INFT Interface also defined in that contract. Flow enacts standardization by espliciting the Interface (not the Resource or Contract) that the current contruct implements. This means that, in order to comply with the NonFungibleToken standard, this NFT implementation must follow the INFT Interface itself.

        NOTE2: It was possible to define the INFT standard in its own file (not advisable, but technically possible). In this case, this NFT should implement the standard something like this:
            
            pub resource NFT: INFT.INFT
        
        assuming that the Interface was defined in a file named INFT.cdc
    */
    access(all) resource NFT: NonFungibleToken.INFT {
        access(all) let id: UInt64
        
        init() {
            self.id = self.uuid
        }

        /*
            Every NFT Resource is going to have the ability to create empty Collection Resources. This might seem a bit of an overkill, but it kinda makes sense, given that it is the Contract that creates the Collection Resource actually.

            NOTE: That bit after the ':' defining the return type of the Resource returned is indeed a lot of overkill, but that's how I roll. The interpreter is happy with simply ': @Collection'. But I like to be specific, since it is very helpful when I need to review this code in a year or something.
            In this case I'm specifying every bit of information I can about the return type, namely, the parent contract (FooBar), the Resource name (Collection) and all the interfaces it implements (the bits between '{}'). The Interfaces are optional
        */
        access(all) fun createEmptyCollection(): @NonFungibleToken.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.Provider} {
            // This function does not creates an empty Collection by itself but it simply invokes the dedicated
            // function from a contract initialization
            return <- FooBar.createEmptyCollection()
        }
    }

    // This other Resource serves only to delegate the production of NFT Resources
    // TODO: Test if a random user can create a NFTMinter by invoking this function.
    // TODO: If the previous test was successful, change the access control of this
    // function to access(contract) and re-test this again. It should work...
    access(all) resource NFTMinter {
        // TODO: Test the limits of Flow's access control framework by keeping this resource as
        // access(all) but changing the createNFT function access to access(contract) or access(self)
        // and check that it properly protects this function from being invoked by random users.
        access(all) fun createNFT(): @FooBar.NFT {
            // Call this function to get one FooBar.NFT
            return <- create FooBar.NFT()
        }

        // NFTMinter constructor
        init() {

        }
    }

    /*
        In order to make the storage of multiple NFTs more flexible, this other Collection Resource is implemented.
        This Resource is a 'special' one that it is prepared to hold multiple other Resources of the type @FooBar.NFT.
        This is achieved by implementing this resource with an internal dictionary (Flow's version of Solidity's mappings) which pairs a UInt64 that corresponds to the NFT's id, with a @FooBar.NFT resource.
        Same as before: this instance of the Collection Resource must implement the corresponding Resource in the NonFungibleToken.cdc contract. Consulting the definition of 'Collection' in the NonFungibleToken.cdc file, it turns out that this one implements three Interfaces itself: CollectionPublic, Provider and Receiver. Therefore, this one needs to implent these as well, just like with the NFT above.
    */
    access(all) resource Collection: NonFungibleToken.CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver {
        /*
            This is the main storage parameter of the Collection Resource. Just like with Solidity's mappings
            Flow's dictionaries operates in a very, very similar fashion, namely they connect two variables of
            different types, in a key-value scheme. And, just like the mappings, keys are unique for every dictionay, which implements uniqueness of resources by default.

            NOTE: This internal dictionary specifies that the values HAVE TO BE of type FooBar.NFT. The confusing part here is putting the '@' before the dictionary declaration, and not '{UInt64: @FooBar.NFT}' as expected. This is a known quirk of Cadence.
            TODO: Am I 100% that this is enough to prevent non-FooBar.NFT NFTs in this Collection? Test what happens when a NFT with a different standard is sent to it.
        */
        access(all) var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // FooBar.Collection constructor
        access(self) init() {
            self.ownedNFTs <- {}
        }

        /*
            Deposit function that receives a FooBar.NFT and stores it in this Collection. Doing so is functionally equivalent to save the NFT into storage. This happens because this Collection can only exist in storage (the way this contract is constructed guarantees that, namely by not keeping any internal variables that could keep a Collection outside storage or any other weird behaviours). Therefore, if this Collection can 'hold' NFTs, they are stored indexed to where this Collection is stored as well.
        */
        access(all) fun deposit(token: @NonFungibleToken.NFT) {
            /* 
                First, to do this properly, retrieve 'whatever' might be stored in this internal dictinary, under the key token.id. In principle, this spot should be empty, but this is the difference between a pro Cadence programmer and a amateur one. A pro one predicts all sorts of eventualities.
                The way I do this is by moving whatever might be in the internal dictionary ownedNFTs into a temporary variable and move the input NFT right after into that spot, which somewhat guarantees that I'm moving this token into a empty space.
                After this, my picky nature as a Cadence programmer is going to test the temporary variable, which according to the specification, can be either a @FooBar.NFT or a nil (hence the '?'), but hopefully, it should be a nil. 
            */
            let id: UInt64 = token.id
            let tempToken: @NonFungibleToken.NFT? <- self.ownedNFTs[id] <- token

            if (tempToken != nil) {
                // I cannot do nothing other than emit an Event indicating that a non-nil Resource was already 
                // in storage
                emit FooBar.WrongCollectionItem(id: id, tokenType: tempToken.getType())

                // I still cannot finish this without doing something to the temporary variable.
                destroy tempToken
            }
            else {
                // In this case, though I've confirmed that I have a nil in the temporary variable, Cadence is
                // still looking at it as a potential Resource (because of the '?'), I still need to 'destroy' a nil
                destroy tempToken
            }

            // TODO: Verify if the 'Deposit' event defined in the NonFungibleToken Interface is automatically emitted
            // if this function is executed or if I need to force an emit.
            // The new upgrade is supposed to automate the emission of these events, but I'm not 100% sure of it
            // right now
        }

        /*
            And now the corresponding 'withdraw' function. The existence of the deposit, withdraw and internal storage dictionary are impositions of the NonFungibleToken standard. Implementing this standard guarantees the existence of these functions, so a user can call them from a Collection without needing to check the code that implements such Collection.

            TODO: Check the access control of this function. It is supposed to change a lot with the Crescendo upgrade
        */
        access(all) fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            // The withdrawal process is much simpler, due to a handy default fuction from Cadence dictionaries
            // The 'remove' function actually removes a Resource from a dictionary with the provided key, i.e., this
            // means that the spot in the dictionary under that key is now empty (nil)
            let withdrawToken: @NonFungibleToken.NFT <- self.ownedNFTs.remove(key: withdrawID) ??
                panic("Unable to retrieve a '@FooBar.NFT' token with id ".concat(
                    withdrawID.toString()
                ))

                return <- withdrawToken
                // TODO: Check if the 'Withdraw' event defined in the NonFungibleToken Interface is automatically
                // emit when this function is called or if I need to do an emit somewhere in this function.
                // In principle, the Crescendo upgrade should automate the emission of these events. Need to test it
                // first though
        }

        /*
            The Collection Interface from the NonFungibleToken standard also forces the implementation of a 'getIDs' function that returns a list of all the NFT's ids currently in the collection, and a 'borrowNFT' function to retrieve a Reference (not the actual Resource) to a specific NFT in the Collection
        */
        access(all) view fun getIDs(): [UInt64] {
            // This one is easy thanks to the default functions of Cadence's dictionaries. The NFT IDs are just
            // the internal dictionary's keys
            return self.ownedNFTs.keys
        }

        /*
            And the function to retrieve a Reference to a Reference stored in the Collection. The interesting thing with this function is that it kinda goes around Capabilities, somehow. Running this function returns a Reference to a Resource without needing to do the whole process of saving the Resource to storage first, link it to the public storage and then get a Reference to it via a Capability. Users had to do this, to some degree, when they set up a Collection in their storage, so this function actually "inherits" all that procedure and simplifies the gathering of References.
        */
        access(all) fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {            
            /*
                There are two ways to do this function. One is the commented line that ends in '!', the other option is to use a 'panic' statement.
                Both statements are valid and produce a similar output. The '!' operator is the force-unwrap operator. It returns the value inside an optional (the ones with a '?' at the end) if it contains a value, or it panics and aborts the execution if the optional is a 'nil' instead, i.e., doesn't have a value.
                The only difference from the uncommented statement bellow is that, in that case, I've specified a panic message. So if a 'nil' gets returned, that message is print with the panic statement, instead of just a 'generic' panic from the '!' case.

                In Cadence, every time we retrieve a Resource or Variable from a Resource's internal structure, such as the ownedNFTs dictionary, that value is always an optional to safeguard the possibility of the Resource had been moved somewhere else before. This is standard, so in every case we need to deal with the possibility of a 'nil' being returned instead. This starts by defining the returns type as an optional (by appending a '?' to the return type) and then do some testing, force-cast or force unwrap to get rid of that optional.
            */

            // return (&self.ownedNFTs[id] as &FooBar.NFT{NonFungibleToken.INFT}?)!
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?) ?? 
            panic("Unable to obtain a &FooBar.NFT from the Collection with id ".concat(id.toString()))
        }

        /*
            NOTE: The following functions are part of the new Cadence standard but are not imposed by the old one, which for all effects and purposes, is still the one used in this example. I'm going to put these "new" mandatory functions here more for future reference than anything else.
        */
        // This function returns a dictionary with all the supported types by this Collection. I think the boolean
        // value is a bit of overkill. but lets hope the geniuses behind this standard know what they are doing.
        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let supportedTypes: {Type: Bool} = {}
            supportedTypes[Type<@FooBar.NFT>()] = true
            return supportedTypes
        }

        // This function is a bit similar to the previous one, namely, it checks if the type provided is 
        // supported, it returns the boolean evaluation of it
        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@FooBar.NFT>()
        }

        /*
            Flow/Cadence dictates (at the language level) that any Resource with nested Resources, i.e., Resources that can hold/contain other Resources, these can only be implemented if a destroy() function gets implemented as well. The requirement of this function is necessary to deal with the proper deletion of this type of Resource that, at any point, can contain other Resources. To prevent a user from deleting a Collection from his own account from leaving a bunch of "dangling" Resources on chain. By "dangling" I mean unaccessible. Once a Resource is saved inside a Collection, the only way to recover that Resource is by executing the 'withdraw' function from the Collection itself. If the Collection gets deleted, any containing Resources become inaccessible because the withdraw function doesn't exist anymore, but they still occupy space in the blockchain. The way Flow found to prevent this was to require a mandatory destroy() function for these resources that it is automatically invoked BEFORE deleting the Collection.
            So, what happens to the Resources stored in a Collection when it gets deleted? As predicted, and as it is shown here, they all get deleted as well. 
        */
        access(self) destroy() {
            destroy self.ownedNFTs
        }
    }

    /*
        This function returns a Collection Resource that is guaranteed to be empty because the Collection Resource constructor resets the internal ownedNFTs variable to an empty dictionary

        NOTE: It turns out that, defining the return type for this function as '@FooBar.Collection{NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, NonFungibleToken.Provider}' is no bueno regarding the Interface specification, though Cadence doesn't mind it (I get an error but from the Interface complaining the function signatures don't match, even considering that expliciting the Interfaces is optional).
        So, to synch with the Interface demands, I need to use the shorter version of the return type, i.e., without the Interfaces that are implemented by the resource.

        NOTE2: Because the type FooBar.Collection is a sub-type of NonFungibleToken.Collection (due to having the NonFungibleToken standard fully implemented in FooBar.Collection), it turns out that I can set the return type of this function as either '@FooBar.Collection' or '@NonFungibleToken.Collection', since these are somewhat interchangeable, i.e., I can upcast the FooBar one to the NonFungibleToken or downcast the NonFungibleToken to the FooBar one. Because of this (I think), the contract accepts both return types.
    */
    access(all) fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create FooBar.Collection()
    }

    // This is the contract main constructor
    access(self) init() {
        /*
            This path is used to store the main minter Resource. By setting it as contract property, I can then access this property by instantiating this contract and access it, since it has access(all) tag.    
        */
        self.MinterStoragePath = /storage/fooBarNFTMinter
        self.CollectionStoragePath = /storage/fooBarNFTCollection
        self.CollectionPublicPath = /public/fooBarNFTCollection

        // Set the totalSupply to 0. Obviously this contract is initialized without any pre-configured NFTs
        self.totalSupply = 0

        /*
            Upon initialization, which for this particular case happens when the contract is deployed, create and immediately save a NFTMinter Resource into this contract's storage.
            This is the only time that this function is accessed and this resource created. Upon creation, move this resource immediately into the contract's storage, thus protecting it from external access. Any function invokations from this resource, namely the minting of new NFTs, is now exclusive of this contract since any transaction needs its signature to execute and only this contract has access to its storage area.
        */
        self.account.save(<- create FooBar.NFTMinter(), to: self.MinterStoragePath)
    }
}
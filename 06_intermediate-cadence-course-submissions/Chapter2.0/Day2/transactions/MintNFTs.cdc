// This transaction uses the single Admin resource to mint a couple of NFTs into the various collections
import StandardAdmin from "../contracts/StandardNFTInterface/StandardAdmin.cdc"
import StandardSword from "../contracts/StandardNFTInterface/StandardSword.cdc"
import StandardBow from "../contracts/StandardNFTInterface/StandardBow.cdc"
import StandardShield from "../contracts/StandardNFTInterface/StandardShield.cdc"

transaction(recipient: Address) {
    let swordCollection: &StandardSword.Collection{StandardSword.CollectionPublic}
    let bowCollection: &StandardBow.Collection{StandardBow.CollectionPublic}
    let shieldCollection: &StandardShield.Collection{StandardShield.CollectionPublic}

    let adminMinter: &StandardAdmin.NFTMinter

    prepare(signer: AuthAccount) {
        // Get the references to each Collection
        let userAccount: PublicAccount = getAccount(recipient)

        self.swordCollection = userAccount.getCapability<&StandardSword.Collection>(StandardSword.collectionPublic).borrow() ??
            panic("Account ".concat(recipient.toString()).concat(" does not have a proper Sword Collection set up yet!"))

        self.bowCollection = userAccount.getCapability<&StandardBow.Collection>(StandardBow.collectionPublic).borrow() ??
            panic("Account ".concat(recip
            ient.toString()).concat(" does not have a proper Bow Collection set up yet!"))

        self.shieldCollection = userAccount.getCapability<&StandardShield.Collection>(StandardShield.collectionPublic).borrow() ??
            panic("Account ".concat(recipient.toString()).concat(" does not have a proper Shield Collection set up yet!"))

        // Retrieve the NFT Minter to the internal variable
        self.adminMinter = signer.getCapability<&StandardAdmin.NFTMinter>(StandardAdmin.minterPrivate).borrow() ??
            panic("Account ".concat(signer.address.toString()).concat(" does not have a proper NFT Minter set up in private storage yet!"))

    }

    execute {
        // Mint and deposit a couple of NFT into each Collection
        let sword1: @StandardSword.NFT <- self.adminMinter.mintSword()
        let sword2: @StandardSword.NFT <- self.adminMinter.mintSword()

        self.swordCollection.deposit(token: <- sword1)
        self.swordCollection.deposit(token: <- sword2)

        let bow1: @StandardBow.NFT <- self.adminMinter.mintBow()
        let bow2: @StandardBow.NFT <- self.adminMinter.mintBow()
        let bow3: @StandardBow.NFT <- self.adminMinter.mintBow()

        self.bowCollection.deposit(token: <- bow1)
        self.bowCollection.deposit(token: <- bow2)
        self.bowCollection.deposit(token: <- bow3)

        let shield1: @StandardShield.NFT <- self.adminMinter.mintShield()
        let shield2: @StandardShield.NFT <- self.adminMinter.mintShield()
        // let shield3: @StandardShield.NFT <- self.adminMinter.mintShield()

        self.shieldCollection.deposit(token: <- shield1)
        self.shieldCollection.deposit(token: <- shield2)

        // Now, just for shit and giggles,try to store a Shield NFT into the Sword Collection, just to see what happens
        // self.swordCollection.deposit(token: <- shield3)

        /*
            Okay, this comment was added after I've tried the last command and I need to do a report to undertand what happened.
            First, I had a damn "bug" that was simply preventing me from getting the info from the NFTs with the script that I wrote for that effect and, honestly,
            WAS DRIVING ME CRAZY! No kidding, it took me a whole working day to figure this shit out! Hence why I'm writting this so that, hopefully, I don't make
            that mistake again.
            1. What was happening before I discovered the "bug"?
                So, the bug was on the deposit function, as defined in each of the collections in the Standard Sword, Shield and Bow contracts. The NonFungibleToken.Collection
                interface establishes this function signature:
                    pub fun deposit(token: @NonFungibleToken.NFT)
                Also, the same interface defines the dictionary where the NFTs are stored as:
                    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}
                It is also important to refer at this point that StandardSword.NFT <= NonFungibleToken.NFT, i.e., the StandardSword.NFT (or Bow, Shield, etc) is a more specific
                type than the NonFungibleToken.NFT, the more general type (hence why I need to authorize the reference to go from StandardSword.NFT to NonFungibleToken.NFT - 
                because I'm going "up", i.e., upcasting from a more specific to a more general type). Another way to think about this is, because of the use of interfaces, a
                StandardSword.NFT is always a subset of a NonFungibleToken.NFT but the opposite is not neccessarily true, hence why the authorization is needed 
                (this is high level Cadence BTW).
                In the bugged version, I was forgetting to downcast the recived NonFungibleToken.NFT into a more specific StandardSword.NFT before adding it to the storage
                dictionary. The deposit function was not complaining because, as the dictionary respects, it can hold either the more general or the more specific type: both
                fit in the "type size" defined. If the ownedNFTs was defined as ownedNFTs: @{UInt64: StandardSword.NFT} instead, trying to deposit a NonFungibleToken.NFT in it would
                raise an error because there are no guarantees that the NonFungibleToken.NFT is a StandardSword.NFT. Cadence doesn't take chances with this.
                But because the NonFungibleToken interface also forces this ownedNFT dictionary to be of the more general type, i.e., NonFungibleToken.NFT, I cannot define this
                dictionary any other way without violating the interface rules.
                The bigger problem was, as you can see above in the minting action, I'm minting the NFTs as the more specific type. But when I was depositing them
                right after, because I was not downcasting them, from the Cadence point of view, they were NonFungibleToken.NFTs after all once they got stored in the 
                ownedNFTs dictionary. The level of nuace in this case is off the charts! That's why it took me ages to discover this.
                So, later on, in the script that tries to get references to them by invoking the borrowSwordNFT, which upcasts them back to NonFungibleToken.NFTs 
                (which is followed by another downcast right after, which is mightly confusing I might say...), that first upcast was blowing up because I was trying to
                upcast (or force cast as they say) a NonFungibleToken.NFT to... a NonFungibleToken.NFT, and aparently that is a big NO NO. The actual error that I was
                getting was:

                    error: failed to force-cast value: expected type `&StandardSword.NFT`, got `auth &NonFungibleToken.NFT`

                Which makes sense considering all that I've written so far! I was not downcasting the initial token before storing it, so when I tried to upcast it,
                thinking that it was in a more specific type, boom, it broke because it got an unexpected type! It seems that Cadence does not likes to upcast a
                more general type into itself.

            2. Solution:
                Adding the line:
                    let token: @StandardSword.NFT <- token as! @StandardSword.NFT
                to the beginning of the deposit function solved everything. The types are now in their expected format at all stages of the run and everything works!
                Check the code for Chapter2.0, Day2 for details on how to properly work with these things

            3. Weird stuff that should have made me realize something was wrong:
                The interesting thing was, when I was forgetting to downcast the NFT before depositing it, I was able to run that commented deposit line above, the one that
                deposits a StandardShield.NFT into a Sword collection. Why was this OK? Because without downcasting, storing a specific NFT into a more general dictionary is
                OK. The sizes "fit".
                So when I corrected the function, why did it stopped working?
                It was not the "store" part that was throwing the error but the downcasting instruction instead. That deposit instruction executes the deposit function by
                providing a more specific StandardShield.NFT when the function expects a more general NonFungibleToken.NFT as input. So far so good. But the first instruction
                of the fixed deposit function now tries to downcast the input, which at that point is a NonFungibleToken.NFT for all cases and purposes, into a more specific
                StandardSword.NFT. But because I'm actually providing a StandarShield.NFT, I'm actually trying to downcast a Shield into a Sword. Not only both types are 
                at the same level of specificity, which should be enough to raise an error, but the types are also incompatible, hence this error:
                    
                    error: failed to force-cast value: expected type `StandardSword.NFT`, got `StandardShield.NFT`
                
                And that's why these lines are now commented in this transaction.



        */
    }
}
 
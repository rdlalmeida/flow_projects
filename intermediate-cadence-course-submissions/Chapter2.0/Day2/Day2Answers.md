1. Design your own contracts such that you use at least one access(account) function that gets called in a contract within the same account. Explain why you had to use <code>access(account)</code>.

Okay, so I went on a bit of a tangent, a really long one actually, on this one. I was going through the initial contracts, the Bow, Shield and Sword ones, and realized that we setup a Collection for each one of these tokens. Besides having a lot of repeated contract code, because the NonFungibleToken interface defines the NFT specifications and the Collection specifications, which means that each of the NFT contracts are forced to also define their own Collections.

And so I wondered "Can I split the NonFungibleToken interface into two interfaces, one just for the NFT stuff and the other just for the Collection stuff?", just to avoid all the Collection stuff in the NFT contracts, which immediately raised another question: "Can I store multiple NFT types in one Collection?"

And there I went on my quest to find out... It took me a few days (mostly because I don't have as much free time as during the Beginner's Booth Camp) but the short answer is, Yes, kinda..

It is possible to create a NFT and Collection interfaces in independent files, create the NFT contracts without specifying a Collection in those files and then create a "general" Collection interface that can hold multiple NFT types. That's the good news. The bad news are that, code wise, the savings from not having to set up Collections in the individual contracts are lost by having to define a much more complicated Collection interface and respective implementations.

This is because, in order to save multiple NFT types in one collection, and keep all the deposit and retrieval functionalities as with the simpler implementation, I had to add a whole new layer of mechanics based on Types and getType() and such, as well as a new internal dictionary to keep track of which NFT id corresponds to which type.

The key to achieve this is that, when we deposit, lets say, a Bow.NFT type in a NonFungibleToken.Collection, the deposit function expects a @NonFungibleToken.NFT as input, it does kinda upcast the received token into NonFungibleToken.NFT upon deposit, but internally, in the self.ownedNFTs dictionary, the token maintains the Bow.NFT type!

So I kinda exploited this to create this a single Collection interface that could hold various NFT types... to a degree. I still need to define a priori which Types I'm going to store in there, but there are no limitations to how many.

So here is the code:
I started by splitting the NonFungibleToken interface into a NFT only interface, named NonFungibleTokenSimple:

(I'll leave just a link to the file in my github, otherwise, if I paste the code here, this is going to be gigantic...)

* NonFungibleTokenSimple.cdc:

https://github.com/rdlalmeida/common_resources/blob/main/contracts/NonFungibleTokenSimple.cdc

The NFT interface is actually quite simple, but the Collection one... not so much...

* NonFungibleTokenCollection.cdc:

https://github.com/rdlalmeida/common_resources/blob/main/contracts/NonFungibleTokenCollection.cdc

Now for the Bow, Shield and Sword contracts, implemented with the simpler NFT interface (which implement the <code>access(account)</code> functions, as requested):

* MyBow.cdc

https://github.com/rdlalmeida/intermediate-cadence-course-submissions/blob/main/Chapter2.0/Day2/contracts/MyNewNFTInterface/MyBow.cdc

* MyShield.cdc

https://github.com/rdlalmeida/intermediate-cadence-course-submissions/blob/main/Chapter2.0/Day2/contracts/MyNewNFTInterface/MyShield.cdc

* MySword.cdc

https://github.com/rdlalmeida/intermediate-cadence-course-submissions/blob/main/Chapter2.0/Day2/contracts/MyNewNFTInterface/MySword.cdc

The star of this exercise is the implementation of the Collection contract, under the NonFungibleTokenCollection interface. As expected, it is enormous and super complex, just like I like it:

* MyCollection.cdc

https://github.com/rdlalmeida/intermediate-cadence-course-submissions/blob/main/Chapter2.0/Day2/contracts/MyNewNFTInterface/MyCollection.cdc

The rest follows the same logic as before. Next, the Admin resource that can mint NFTs by accessing the <code>access(account)</code> functions:

* MyAdmin.cdc

https://github.com/rdlalmeida/intermediate-cadence-course-submissions/blob/main/Chapter2.0/Day2/contracts/MyNewNFTInterface/MyAdmin.cdc

Contracts are done. Next, in this case I need only two transactions to set up this for testing: one to create the general Collection:
* CreateMyCollection.cdc

https://github.com/rdlalmeida/intermediate-cadence-course-submissions/blob/main/Chapter2.0/Day2/transactions/CreateMyCollection.cdc

And another one to mint NFTs of several types into the general Collection:
* MintMyNFTs.cdc

https://github.com/rdlalmeida/intermediate-cadence-course-submissions/blob/main/Chapter2.0/Day2/transactions/MintMyNFTs.cdc

Finally, a script to check if all this junk really works (Spoiler: it does!)
* GetAllNFTsInMyCollection.cdc

https://github.com/rdlalmeida/intermediate-cadence-course-submissions/blob/main/Chapter2.0/Day2/scripts/GetAllNFTsInMyCollection.cdc

As with the original set of contracts, the minting functions are limited with the <code>access(account)</code>, which meant that they can only be minted from a Resource that exists in the same account where the NFT contracts are deployed.

2. Starting from this contract: https://flow-view-source.com/mainnet/account/0x921ea449dffec68a/contract/Flovatar

* Find 1 variable that uses access(account)

- An obvious one is right at beginning (line 32):
    ```cadence
    access(account) var royaltyCut: UFix64
    ```

* Find 1 function that uses access(account)

- The function that sets the <code>access(account)</code> variable above:
    ```cadence
    access(account) fun setRoyaltyCut(value: UFix64){
        self.royaltyCut = value
    }
    ```

Using the function you found, explain why it uses that access modifier and where it gets called in a different contract in that same account

This function sets an important parameter that should be only be modifiable by the owner of the account, namely the percentage to apply in royalties when transacting a Flovatar. The best way to protect this is with the <code>access(account)</code> modifier which limits the invocations of this function to contracts deployed within the same account. Yet, I was not able to find any records of any <code>access(account)</code> functions in the Flovatar contract that are called in any other contract in the account. The only other contract that imports this one is the FlovatarMarketplace and neither the function that I indicated above, nor any of the other 3 that have the same access modifier are called there. But they could if needed.
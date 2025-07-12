# Ricardo's Resource-based voting platform

## Who am I?
I'm Ricardo Almeida, a 3rd year PhD student from the University of Pisa and University of Camerino, both in Italy. I'm on my last year of a National PhD Program on Blockchain and Distributed Ledger Technology, the first of its kind in Italy. My research has been primarily centred on remove voting systems, i.e., voting platforms that do not restrict voters geographically, but recently I was able to "convince" my advisors to switch the base technology in which I'm exploring this concept towards the resource-based paradigm exhibited by smart contract programming languages such as Cadence and Move.

The concept in itself is equally exciting and unexplored and I decided to kill two birds in one stone by exploring it from the point of view of a voting platform. I've been programming and exploring the Flow blockchain and Cadence since early 2022. I was extremely curious and attracted by how radical the resource-based paradigm was when compared to the "traditional" way of representing digital assets in a blockchain context, which is essentially the mapping-based strategy employed in Solidity and related languages. The resource paradigm was far cleaner, secure and so, so much fun to work with when compared to Solidity. I've been trying to "sell" this to my advisor team since then, but unfortunately I had to wait for the rest of the research community to catch on to get any traction worth mentioning.

## What am I working in right now?
One day my main advisor requested a meeting with me. She had went to an academic conference in 2024 (somewhere in Europe, don't remember exactly where) and it turned out that Move and resources were all the rage in there. There were a lot of articles being presented over the topic and she could see that this paradigm was finally seeping into the academic world. Even though she was only half paying attention whenever I was explaining how Flow and Cadence worked, she understood enough to realise that one of her own students was looking at this for a full 2 years up to that point. Now I look like this visionary, but I had to eat a lot of crow before getting vindicated.

Currently, my researched has shifted towards providing a full analysis of the resource-based concept:
- Where did it came from?
- How does it work exactly?
- Who's using it?
- What are the advantages and disadvantages over the ledger-based (e.g. Ethereum) "classical" model?

I'm working on this alongside with the development of the first resource-based remote voting platform, which I obviously want to develop in Cadence and Flow.

# The Resource-based voting platform (I don't have a cool name for it yet... :confused:) 
The basis of my idea is summarised in the figure bellow:

<img width="905" height="844" alt="15_Resource_based_enc_framework" src="https://github.com/user-attachments/assets/4345bb2c-45b5-4c9c-8f8e-c80359147dd7" />

From the point of view of other remote voting systems, even blockchain-based ones, there's not a lot added to this approach, given that it is a tried and successful one. The biggest addition from my part is to use resources to abstract ballots as a way to research how these can fare in such context.

**NOTE:** From this point onwards, for simplicity sake, I'm referring to any resource instance in a capitalised fashion. A "Ballot" refers to an instance of a Cadence resource defined through a smart contract and minted using the usual admin-type resource. A "ballot" on the other hand refers to the general object.

The star of this system is the Ballot resource. I've build this one to emulate a real world ballot as much as possible (given than resources are inspired by *linear types* and these intend to represent real-world values as well). Just like with real-life ballots, Ballot's ownership is implied from the account owner whose storage they exist at any point.
Ballots are printed on demand by an authority (The *Election Authority (EA)* in the figure) and delivered to the voter's account upon successful registration/authentication. This emulates a physical voting booth where a voter gets a paper ballot printed by the election organisers after these check that the voter's ID is an eligibility list.

## System Actors:
- **Voter:** The main actor in the system. The registration process inserts $$E_{j}$$
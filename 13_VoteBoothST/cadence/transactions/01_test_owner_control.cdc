// TODO: Why is this bullshit transaction crashing the emulator???? It makes no fucking sense! If I literally clean (or comment) every single line other than the really necessary ones, it still crashes! Check this ASAP!

import "VoteBoothST"

transaction() {
    prepare(signer: auth(Storage) &Account) {
        // Test the OwnerControl resource by pulling an authorized reference and running some functions of it
        let ownerControl: @VoteBoothST.OwnerControl <- signer.storage.load<@VoteBoothST.OwnerControl>(from: VoteBoothST.ownerControlStoragePath) ??
        panic(
            "Unable to retrieve a valid @VoteBoothST.OwnerControl at "
            .concat(VoteBoothST.ownerControlStoragePath.toString())
            .concat(" from account ")
            .concat(signer.address.toString())
        )
/*
            Use the OwnerControl reference to check that both the ballotOwner and owners internal dictionaries were created empty. Safe to say that this function should only be called right after the contract is deployed. After that, the expectation is that these structures are going to be filled
        */
        let ballotOwners: {UInt64: Address} = ownerControl.getBallotOwners()
        
        if (ballotOwners != {}) {
            panic(
                "ERROR: The OwnerControl resource at "
                .concat(VoteBoothST.ownerControlStoragePath.toString())
                .concat(" has a non-empty ballotOwners dictionary in it!")
            )
        }

        let owners: {Address: UInt64} = ownerControl.getOwners()

        if (owners != {}) {
            panic(
                "ERROR: The OwnerControl resource at "
                .concat(VoteBoothST.ownerControlStoragePath.toString())
                .concat(" has a non-empty owners dictionary in it!")
            )
        }

        // If all went OK, log a simple message acknowledging it
        log(
            "The OwnerControl resource at "
            .concat(VoteBoothST.ownerControlStoragePath.toString())
            .concat(" for account ")
            .concat(signer.address.toString())
            .concat(" is consistent. ballotOwners and owners are still empty.")
        )

        // Send the resource back into storage
        signer.storage.save<@VoteBoothST.OwnerControl>(<- ownerControl, to: VoteBoothST.ownerControlStoragePath)
    }

    execute {
    }
}
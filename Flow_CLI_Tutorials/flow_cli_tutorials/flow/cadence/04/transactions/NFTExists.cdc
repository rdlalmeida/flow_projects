import BasicNFT from "../contracts/BasicNFT.cdc"

/*
    This transaction checks if an NFT exists in the storage of the given account by trying to borrow from it.
    If the borrow succeeds (returns a non-nil value), the token exists!
*/
transaction() {
    prepare(account: AuthAccount) {
        let existingNFT = account.borrow<&BasicNFT.NFT>(from: BasicNFT.baseLocation) 
        ?? panic("Something very wrong has happened!")

        if ( existingNFT != nil) {
            let refNFT = existingNFT as! &BasicNFT.NFT 
            log("The token exists and has an id = ".concat(refNFT.id.toString()))
        }
        else {
            log("No token found!")
        }
    }
}
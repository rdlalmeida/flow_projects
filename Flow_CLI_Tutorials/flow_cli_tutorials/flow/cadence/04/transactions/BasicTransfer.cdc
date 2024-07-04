import BasicNFT from "../contracts/BasicNFT.cdc"

/* Basic transaction for two accounts to authorize to transfer an NFT */

transaction() {
    prepare(signer1: AuthAccount, signer2: AuthAccount) {
        let signer2Storage: StoragePath = /storage/TransferredNFT

        // Load the NFT from signer1's account storage
        let nftToTransfer <- signer1.load<@BasicNFT.NFT>(from: BasicNFT.baseLocation)

        // Save it to signer2's storage account
        signer2.save(<- nftToTransfer, to: signer2Storage)

        log("Successfully transfered a NFT from ".concat(BasicNFT.baseLocation.toString()).concat(" to ".concat(signer2Storage.toString())))
    }

    execute {

    }
}
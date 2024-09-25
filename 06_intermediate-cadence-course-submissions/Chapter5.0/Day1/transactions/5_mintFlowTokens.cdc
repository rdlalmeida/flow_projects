/*
    This transaction simply mints a bunch of $FLOW tokens to the admin (emulator) account, mainly to then transfer them for that exercise where
    RicardoCoin tokens are traded by $FLOW.
    Deploying the FlowToken contract does not add $FLOW tokens to the deployer account, so I need to do a transaction for that
    ...
    I just realise I don't really need these one. I can just mint the tokens on demand on the transfer function
*/

import FlowToken from "../contracts/FlowToken.cdc"
import FungibleToken from "../../../../common_resources/contracts/FungibleToken.cdc"

transaction(amount: UFix64) {

    let adminReference: &FlowToken.Administrator
    let adminVault: &FlowToken.Vault{FungibleToken.Receiver}

    prepare(signer: AuthAccount){
        self.adminReference = signer.borrow<&FlowToken.Administrator>(from: FlowToken.adminStorage) ??
            panic("Unable to retrieve an Adminstrator Reference from account ".concat(signer.address.toString()))

        self.adminVault = signer.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(FlowToken.vaultReceiverPublic).borrow() ??
            panic("Unable to retrieve a Vault Receiver reference from account ".concat(signer.address.toString()))
    }

    execute {
        let minter: @FlowToken.Minter <- self.adminReference.createNewMinter(allowedAmount: amount)

        self.adminVault.deposit(from: <- minter.mintTokens(amount: amount))

        destroy minter
    }
}
// import Record from 0xf8d6e0586b0a20c7
// import NonFungibleToken from 0xf8d6e0586b0a20c7
import Record from "../contracts/Record.cdc"
import NonFungibleToken from "../../../../common_resources/contracts/NonFungibleToken.cdc"

transaction() {
    prepare(signer: AuthAccount) {
        // Before saving the new collection, retrieve any stuff that might be still stored in the path to ensure that the save goes well
        // NOTE: If a valid collection already exists in this path, its going to get smoked, along with any NFTs in it. This is only advisable
        // for this training stuff (This allows me to change the Collection parameters in the contract and re test the whole thing with minimal hassle)
        signer.unlink(Record.CollectionPublicPath)
        let randomResource: @AnyResource <- signer.load<@AnyResource>(from: Record.CollectionStoragePath)
        destroy randomResource

        // Storage is clean again. Carry on

        // Create the collection. Force cast it to the desired type since the function returns a NonFungibleToken.CollectionPublic as default
        let myCollection: @Record.Collection <- Record.createEmptyCollection()

        log("Collection created for user ".concat(signer.address.toString()))

        // Store the created resource into storage
        signer.save(<- myCollection, to: Record.CollectionStoragePath)

        log("Saved a collection to ".concat(Record.CollectionStoragePath.toString()))

        // Link it to the public path too
        signer.link<&Record.Collection{Record.CollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(Record.CollectionPublicPath, target: Record.CollectionStoragePath)

        log("Collection linked to the public path at ".concat(Record.CollectionPublicPath.toString()).concat(" for user ").concat(signer.address.toString()))
    }

    execute {

    }
}
 
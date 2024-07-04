transaction(publicKey: String) {
    prepare(signer: AuthAccount) {
        let pub_key = PublicKey(
            publicKey: publicKey.decodeHex(),
            signatureAlgorithm: SignatureAlgorithm.ECDSA_P256
        )

        let newAccount = AuthAccount(payer: signer)

        newAccount.keys.add(
            publicKey: pub_key,
            hashAlgorithm: HashAlgorithm.SHA3_256,
            weight: 1000.0
        )

        log("Created a new account with address: ".concat(newAccount.address.toString()))
    }
}

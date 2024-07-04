#!/bin/bash

# TODO: Capture the output from the createAccount.cdc transaction and edit this file and, more importantly, the corresponding flow.json

# The path to the transaction file used to create a new account
CREATE_ACCOUNT_TRANSACTION_PATH=$HOME/Flow_projects/common_resources/transactions/createAccount.cdc

# Write down the public keys for the accounts to create (the corresponding private keys are already stored in flow.json but are set here for reference
ACCOUNT01_PUBKEY=8e69871f04fdefd7932b606cde4b30b51398cca91b2c409ffd1f6f911de52cddecba67c759207a97581b5a1882a442124c69d773bf0e828f4d03a1860425cf39
ACCOUNT01_PRIVKEY=24131830f069dfb1eb0832bea830807dde1b98f0533119693bd94d9ed0cda286
ACCOUNT01_ADDRESS=0xe03daebed8ca0615
ACCOUNT01_MNEMONIC="town empty equal caught prize seminar hollow raven book replace frown muscle"

ACCOUNT02_PUBKEY=aa9006b45921d7a7811207bc904c87a2c98cd90bcc393917a0f7515779b070984ac51dbf334589fdcc133700cc85a0665a314258cb81e8e03d285dda10acfa62
ACCOUNT02_PRIVKEY=839bea9c1bbbd9893192e774cb04dd39cacf008264886e2336df87840618a7b4
ACCOUNT02_ADDRESS=0x045a1763c93006ca
ACCOUNT02_MNEMONIC="captain prison fix indoor process squirrel when delay town category father stage"

ACCOUNT03_PUBKEY=4028b95aeabeb7572d052fe2294cbc9f50632234ed5f8b4dee7101474f1ef5b373cb7c3ada9c1f5404f73f155656f08eb6f17c20452cb465715d8bbb30ca2f9d
ACCOUNT03_PRIVKEY=059ab1881bf258241aae485bb509c6f62e25bf8d032790cd6b7586ffe8359c93
ACCOUNT03_ADDRESS=0x120e725050340cab
ACCOUNT03_MNEMONIC="woman peasant empty draw merry decorate flat rail hour surge circle ignore"

ACCOUNT04_PUBKEY=722d1025378f9ea86fbd563432281354b95dbd9b7ae57da56b3abed84a61a1ffea2a6137644907dc587210d9027842c1d34b6ffbc76c7b855ff03cccf1a0d056
ACCOUNT04_PRIVKEY=b9b120a2cc035e5f8e42ca633df5091c9660b0e24d0336cc60ff57a635a7a12e
ACCOUNT04_ADDRESS=0xf669cb8d41ce0c74
ACCOUNT04_MNEMONIC="man element delay auto tired mandate during swing amazing wheel summer coyote"

ACCOUNT05_PUBKEY=25f32079cce55d96ff40471ef693b5248be585c0efa92e12b04c6eafa4c15df6bba9ead416e5bba5aa364f963435e42451f958d2b9c4f34f3be16c99ba9e26ad
ACCOUNT05_PRIVKEY=ef726b3d24265e90ee59430af5bbef73132d2680ea3455441d67bf02005c762e
ACCOUNT05_ADDRESS=0x192440c99cb17282
ACCOUNT05_MNEMONIC="hope size hundred victory hobby crystal cheese nice sponsor weapon palm giraffe"

accounts_to_create=(${ACCOUNT01_PUBKEY} ${ACCOUNT02_PUBKEY} ${ACCOUNT03_PUBKEY} ${ACCOUNT04_PUBKEY} ${ACCOUNT05_PUBKEY})
for account in "${accounts_to_create[@]}"
do
	account_setup="flow transactions send ${CREATE_ACCOUNT_TRANSACTION_PATH} $account --signer emulator-account --network emulator"

	echo "Creating Account ${index}..."
	echo ${account_setup}

	eval $account_setup
	
	echo "Account ${index} created successfully!"

	((index+=1))
done
 
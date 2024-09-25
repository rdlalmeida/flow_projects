#!/bin/bash

# The path to the transaction file used to create a new account
CREATE_ACCOUNT_TRANSACTION_PATH=$HOME/Flow_projects/Flow_CLI_Tutorials/flow_cli_tutorials/flow/cadence/00/transactions/createAccount.cdc

# Write down the public keys for the accounts to create (the corresponding private keys are already stored in flow.json but are set here for reference
ACCOUNT01_PUBKEY=0d766679eb92f783566331af50cccf8e6c39f4a35c89d8dd957185adf02338975e38a44a9caaeccd2b5cdb686a64513d86d38bcb97ddab180a3404f8aa5dde09
ACCOUNT01_PRIVKEY=2df342adc4f8fc5a2c91c6759c766096b2afe3660a861d4b83f815b7d3e06b27

ACCOUNT02_PUBKEY=6fbd9bad2b2b75c4bc2ee2bc09b211308770964ed2e07dc2cf690253315d948d9d9281e3a3c150c543b9f21138782810fc7c9d4755c8bc7416c03588be50935d
ACCOUNT02_PRIVKEY=69f067810cb6858662126df375e9f9a249e8441abeaeadde837335f82659b5d4

ACCOUNT03_PUBKEY=d1f588984e4a80e686291b6d6c4bb44c6716bb3320d37cc4534178d8ebd302089cdf7e0eff2a927d0093994164c49b5c9b7ef44992f74465febb170fd0ecc071
ACCOUNT03_PRIVKEY=61d9ac65e0a1fc9295b1fa377977e04ab02a616ec313d057d276d3e259fa44c2

ACCOUNT04_PUBKEY=33751438b6125254679649a8fd2e0ddb8657185628dd55e7bd3005061631e24be1cd0f7b5713b6d0dc4d79343a826349f35a8c7a5467e6e67a382c3cc9cf188f
ACCOUNT04_PRIVKEY=6e0e03c1e7cd08d15d8b10bc000ec8a15a3b7031526053e99e37eda9713d0320

accounts_to_create=(${ACCOUNT01_PUBKEY} ${ACCOUNT02_PUBKEY} ${ACCOUNT03_PUBKEY} ${ACCOUNT04_PUBKEY})
for account in "${accounts_to_create[@]}"
do
	account_setup="flow transactions send ${CREATE_ACCOUNT_TRANSACTION_PATH} $account --signer emulator-account --network emulator"

	echo "Creating Account ${index}..."
	echo ${account_setup}

	eval $account_setup
	
	echo "Account ${index} created successfully!"

	((index+=1))
done

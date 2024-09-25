#!/bin/bash

# This one is but a simple script to automate certain runs, just to save some time

EMULATOR_ADDRESS="0xf8d6e0586b0a20c7"
EMULATOR="emulator-account"

ACCOUNT01_ADDRESS="0x045a1763c93006ca"
ACCOUNT01=account01

ACCOUNT02_ADDRESS="0x120e725050340cab"
ACCOUNT02="account02"

ACCOUNT03_ADDRESS="0xf669cb8d41ce0c74"
ACCOUNT03="account03"

ACCOUNT04_ADDRESS="0x192440c99cb17282"
ACCOUNT04="account04"

ACCOUNT05_ADDRESS="0xfd43f9148d4b725d"
ACCOUNT05=account05

NETWORK=emulator

# Deploy a contract
CONTRACT_PATH=contracts/Shapes.cdc
CONTRACT_NAME=TestNFT
SIGNER=emulator-account

# deploy_contract="flow accounts add-contract $CONTRACT_NAME $CONTRACT_PATH --signer $SIGNER --network $NETWORK"
# The Update version of the last command
deploy_contract="flow accounts update-contract $CONTRACT_PATH --signer $SIGNER --network $NETWORK"

# Run transaction 1
TRANSACTION1_PATH=transactions/createUserCollection.cdc
TRANSACTION1_ARGS=""
TRANSACTION1_SIGNER=ACCOUNT01

run_transaction1="flow transactions send $TRANSACTION1_PATH $TRANSACTION1_ARGS --signer $TRANSACTION1_SIGNER --network $NETWORK"

# Run transaction 2
TRANSACTION2_PATH=transactions/createUserCollection.cdc
TRANSACTION2_ARGS=""
TRANSACTION2_SIGNER=ACCOUNT02

run_transaction1="flow transactions send $TRANSACTION1_PATH $TRANSACTION1_ARGS --signer $TRANSACTION1_SIGNER --network $NETWORK"

# Run transaction 3
TRANSACTION2_PATH=Chapter2.0/Day2/transactions/MintTestNFTs.cdc
TRANSACTION2_ARGS="0xe03daebed8ca0615"
TRANSACTION2_SIGNER="emulator-account"

run_transaction2="flow transactions send $TRANSACTION2_PATH $TRANSACTION2_ARGS --signer $TRANSACTION2_SIGNER --network $NETWORK"

# Run script
SCRIPT1_PATH=Chapter2.0/Day2/scripts/GetAllTestNFTsInCollection.cdc
SCRIPT1_ARGS="0xe03daebed8ca0615"

run_script1="flow scripts execute $SCRIPT1_PATH $SCRIPT1_ARGS --network $NETWORK"

# Run stuff here:
echo "Running ${deploy_contract}"
eval $deploy_contract

echo "Running ${run_transaction1}"
eval $run_transaction1

echo "Running ${run_transaction2}"
eval $run_transaction2

echo "Running ${run_script1}"
eval $run_script1
 
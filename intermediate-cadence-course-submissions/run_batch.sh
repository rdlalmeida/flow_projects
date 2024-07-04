#!/bin/bash

# This one is but a simple script to automate certain runs, just to save some time

NETWORK=emulator
# NETWORK=testnet

# Deploy a contract
CONTRACT_PATH=Chapter5.0/Day1/contracts/RicardoCoinSuperAdmin.cdc
CONTRACT_NAME=RicardoCoinSuperAdmin
SIGNER=emulator-account

# deploy_contract="flow accounts add-contract $CONTRACT_NAME $CONTRACT_PATH --signer $SIGNER --network $NETWORK"
# The Update version of the last command
# deploy_contract="flow accounts update-contract $CONTRACT_PATH --signer $SIGNER --network $NETWORK"

# Run transaction 0
# Setup Vaults for testnet-account-admin
TRANSACTION0_PATH=Chapter5.0/Day1/transactions/7_setupSwapAccount.cdc
TRANSACTION0_ARGS=""
TRANSACTION0_SIGNER=testnet-account-admin

run_transaction0="flow transactions send $TRANSACTION0_PATH $TRANSACTION0_ARGS --signer $TRANSACTION0_SIGNER --network $NETWORK"

# Run transaction 1
# Setup Vaults for testnet-account-01
TRANSACTION1_PATH=Chapter5.0/Day1/transactions/7_setupSwapAccount.cdc
TRANSACTION1_ARGS=""
TRANSACTION1_SIGNER=testnet-account-01

run_transaction1="flow transactions send $TRANSACTION1_PATH $TRANSACTION1_ARGS --signer $TRANSACTION1_SIGNER --network $NETWORK"

# Run transaction 2
# Setup Vault for testnet-account-02
TRANSACTION2_PATH=Chapter5.0/Day1/transactions/7_setupSwapAccount.cdc
TRANSACTION2_ARGS=""
TRANSACTION2_SIGNER=testnet-account-02

run_transaction2="flow transactions send $TRANSACTION2_PATH $TRANSACTION2_ARGS --signer $TRANSACTION2_SIGNER --network $NETWORK"

# Run script 0
# Verify Successful vault creation
SCRIPT0_PATH=Chapter5.0/Day1/scripts/4_profileVaults.cdc
SCRIPT0_ARGS="[0xb7fb1e0ae6485cf6,0x78617072bc4306ab,0x8ae00fb5a872b8f4,0x0c838d98cae56592]"

run_script0="flow scripts execute $SCRIPT0_PATH $SCRIPT0_ARGS --network $NETWORK"

# Run transaction 3
# Mint 100 $FLOW tokens for testnet-account-01
TRANSACTION3_PATH=Chapter5.0/Day1/transactions/2_mintFlowTokens.cdc
TRANSACTION3_ARGS="0x78617072bc4306ab 100.0"
TRANSACTION3_SIGNER=testnet-account-admin

run_transaction3="flow transactions send $TRANSACTION3_PATH $TRANSACTION3_ARGS --signer $TRANSACTION3_SIGNER --network $NETWORK"

# Run transaction 4
# Mint 100 $FLOW tokens for testnet-account-02
TRANSACTION4_PATH=Chapter5.0/Day1/transactions/2_mintFlowTokens.cdc
TRANSACTION4_ARGS="0x8ae00fb5a872b8f4 100.0"
TRANSACTION4_SIGNER=testnet-account-admin

run_transaction4="flow transactions send $TRANSACTION4_PATH $TRANSACTION4_ARGS --signer $TRANSACTION4_SIGNER --network $NETWORK"

# Run script 1
# Verify successful mints
SCRIPT1_PATH=Chapter5.0/Day1/scripts/4_getProfileVaults.cdc
SCRIPT1_ARGS="[0xb7fb1e0ae6485cf6,0x78617072bc4306ab,0x8ae00fb5a872b8f4]"

run_script1="flow scripts execute $SCRIPT1_PATH $SCRIPT1_ARGS --network $NETWORK"

# Run script
# SCRIPT1_PATH=Chapter2.0/Day2/scripts/GetAllTestNFTsInCollection.cdc
# SCRIPT1_ARGS="0xe03daebed8ca0615"

# run_script1="flow scripts execute $SCRIPT1_PATH $SCRIPT1_ARGS --network $NETWORK"

# Run stuff here:
# echo "Running ${deploy_contract}"
# eval $deploy_contract

echo "Running ${run_transaction0}"
eval $run_transaction0

echo "Running ${run_transaction1}"
eval $run_transaction1

echo "Running ${run_transaction2}"
eval $run_transaction2

echo "Running ${run_script0}"
eval $run_script0

echo "Running ${run_transaction3}"
eval $run_transaction3

echo "Running ${run_transaction4}"
eval $run_transaction4

echo "Running ${run_script1}"
eval $run_script1

# echo "Running ${run_script1}"
# eval $run_script1
 
#!/bin/bash

################### VERY IMPORTANT NOTE #####################################################################
# Imports need to come from accounts and not files. Why? Who the fuck knows but it does not work otherwise
# Replace any "import <Module> from <Path>" with 
# "import <Module> from <Account_address_where_the_contract_that_defines_Module_is_deployed>"
# In every transaction, script or contract executed within this script
#############################################################################################################

# Path to where the main flow.json file is
CONFIG_PATH=$HOME/Flow_projects/Flow_CLI_Tutorials/flow_cli_tutorials/flow.json

# A simple base path to the main Flow project to make things easier
BASE_PATH=$HOME/Flow_projects/Flow_CLI_Tutorials/flow_cli_tutorials/flow/cadence

# The path to the transaction file used to setup a new Vault in an account
CREATE_VAULT_PATH=$BASE_PATH/06/transactions/SetupAccount.cdc

# The path to the transaction file used to mint tokens into a Vault
MINT_TOKENS_PATH=$BASE_PATH/06/transactions/MintTokens.cdc

# An array with the handles of the emulator configurated accounts, as defined in the flow.json file
account_alias=("emulator-account" "account01" "account02" "account03" "account04")

# Run a for loop to setup a base Vault in each account
for account in "${account_alias[@]}"
do
    vault_setup="flow transactions send ${CREATE_VAULT_PATH} --config-path ${CONFIG_PATH} --signer $account --network emulator"
    echo "Creating an empty Vault in account $account..."
    echo ${vault_setup}

    eval $vault_setup

    echo "Vault created successfully for account $account"

done

# Another array with the tokens that are going to be minted into each Vault just created
tokens_to_transfer=("400.00" "401.01" "402.02" "403.03" "404.04")

# Array with the addresses of the accounts configured thus far
account_addresses=("0xf8d6e0586b0a20c7" "0x01cf0e2f2f715450" "0x179b6b1cb6755e31" "0xf3fcd2c1a78f5eee" "0xe03daebed8ca0615")

# Run another for loop to mint these tokens into each Vault
array_length=${#account_addresses[@]}
for (( j=0; j<${array_length}; j++ ));
do
    mint_setup="flow transactions send ${MINT_TOKENS_PATH} ${tokens_to_transfer[$j]} ${account_addresses[$j]} --config-path ${CONFIG_PATH} --signer emulator-account --network emulator"

    echo "Minting ${tokens_to_transfer[$j]} tokens into account ${account_address[$j]} Vault..."
    echo ${mint_setup}

    eval $mint_setup

    echo -e "Done!\n"
done
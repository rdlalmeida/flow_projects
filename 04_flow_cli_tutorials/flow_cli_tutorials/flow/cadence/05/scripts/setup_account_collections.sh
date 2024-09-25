#!/bin/bash

# Path to where the main flow.json file is
CONFIG_PATH=$HOME/Flow_projects/Flow_CLI_Tutorials/flow_cli_tutorials/flow.json

# A simple base path to the main Flow project to make things easier
BASE_PATH=$HOME/Flow_projects/Flow_CLI_Tutorials/flow_cli_tutorials/flow/cadence

# The path to the transaction file used to setup a new Collection in an account
CREATE_COLLECTION_PATH=$BASE_PATH/05/transactions/SetupCollection.cdc

# The path to the transaction file used to Mint NFTs into a Collection
MINT_NFT_PATH=$BASE_PATH/05/transactions/NFTMinter.cdc

# The path to the transaction file used to set a NFT for sale in an account
SELL_NFT_PATH=$BASE_PATH/08/transactions/CreateSale.cdc

# An array with the handles of the emulator configurated accounts, as defined in the flow.json file
account_alias=("emulator-account" "account01" "account02" "account03" "account04")

# Array with the addresses of the accounts configured thus far
account_addresses=("0xf8d6e0586b0a20c7" "0x01cf0e2f2f715450" "0x179b6b1cb6755e31" "0xf3fcd2c1a78f5eee" "0xe03daebed8ca0615")

# Run a for loop to setup an Empty Collection in each account
if false; then
    for account in "${account_alias[@]}";
    do
        collection_setup="flow transactions send ${CREATE_COLLECTION_PATH} --signer $account --network emulator"
        echo "Creating an empty Collection in account $account..."
        echo ${collection_setup}

        eval $collection_setup

        echo -e "Collection create in account $account!\n"

    done
fi

# Run another loop to deposit 2 NFTs in each Collection

if false; then
    for account in "${account_addresses[@]}"
    do
        mint_nft="flow transactions send ${MINT_NFT_PATH} $account --signer emulator-account --network emulator"
        echo "Minting an NFT into account $account..."
        echo ${mint_nft}true

        eval $mint_nft

        echo "Minting another one..."

        eval $mint_nft

        echo -e "Done!\n"
    done
fi

# A simple array with the prices to set on the NFT sales
nft_sales=("40.0" "41.1" "42.2" "43.3" "44.3")
array_length=${#nft_sales[@]}

# Since I'm at it, go ahead and set one of the NFTs just minted for sell in each account
if true; then
    for (( j=0; j<${array_length}; j++ ));
    do
        sell_nft="flow transactions send ${SELL_NFT_PATH} ${nft_sales[$j]} --signer ${account_alias[$j]} --network emulator"
        echo "Setting an NFT in account ${account_addresses[$j]} for sale for ${nft_sales[$j]} tokens..."
        echo ${sell_nft}

        eval $sell_nft

        echo -e "Done!\n"
    done
fi
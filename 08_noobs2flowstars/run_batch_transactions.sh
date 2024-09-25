#!/bin/bash

# A simple list of all the configured account addresses, for easy reference, followed by their alias as indicated in the respective flow.json file
EMULATOR_ADDRESS="0xf8d6e0586b0a20c7"
EMULATOR="emulator-account"

ACCOUNT01_ADDRESS="0x045a1763c93006ca"
ACCOUNT01="account01"

ACCOUNT02_ADDRESS="0x01cf0e2f2f715450"
ACCOUNT02="account02"

ACCOUNT03_ADDRESS="0x179b6b1cb6755e31"
ACCOUNT03="account03"

ACCOUNT04_ADDRESS="0xf3fcd2c1a78f5eee"
ACCOUNT04="account04"

ACCOUNT05_ADDRESS="0xe03daebed8ca0615"
ACCOUNT05="account05"

# The base path to the transaction folder to execute.
# NOTE: For this to work properly (because of the transaction imports mainly), this Path has to be relative to the folder where this script resides
TRANSACTIONS_BASE_PATH=./transactions/

# And now an array with all the transactions .cdc files to be executed
transactions_to_execute=(
    "createUserCollection.cdc" 
    "createUserCollection.cdc" 
    "createFLOATEventGroup.cdc" 
    "createFloatEvent.cdc" 
    "createFloatEvent.cdc" 
    "createFloatEvent.cdc" 
    "createEmptyFlowVault.cdc" 
    "mintTestFlowToVault.cdc" 
)

# This next array has all the arguments that each transaction may need. This array NEEDS to match the size of the previous one. If a transaction in the previous
# array does not need/take any arguments, set an empty string ("") in its position. I'm going to validate the array sizes anyways
# NOTE: To cover transactions that may require multiple arguments, the next one is going to be an array of arrays. But same logic: if a transactions in the previous
# array doesn't take any arguments, leave the array empty and that should be it
# NOTE 2: Because bash does not support multidimentional arrays (go figure...), every element of the next array is going to be a String (or a variable that points to one)
# So, if a transaction requires more than one argument to execute, set them as a single string in the correct array position, i.e., "TxArg1 TxArg2 TxArg3" and so on
transaction_arguments=(
    "" 
    "" 
    "'WolfStars' 'https://ipfs.io/ipfs/QmbxVi3HqTMZjA9c7L5spGDLWTBsFuawrKiiQGHwzjh59A?filename=noobs2flowstars_logo.png' 'Noobs to Flowstars creators'" 
    "'Learning01' 'Learning event #1' 'https://ipfs.io/ipfs/QmcWpR9KfPfefGBoTSZwY4V7nVN2bSPdJ6PS7bC6BAP95D?filename=noobs2flowstars_logo2.png' 'www.noobs2flowstars.io' [] [] {}"
    "'Learning02' 'Learning event #2' 'https://ipfs.io/ipfs/QmcWpR9KfPfefGBoTSZwY4V7nVN2bSPdJ6PS7bC6BAP95D?filename=noobs2flowstars_logo2.png' 'www.noobs2flowstars.io' [] [] {}"
    "'Learning03' 'Learning event #3' 'https://ipfs.io/ipfs/QmcWpR9KfPfefGBoTSZwY4V7nVN2bSPdJ6PS7bC6BAP95D?filename=noobs2flowstars_logo2.png' 'www.noobs2flowstars.io' [] [] {}" 
    "" 
    "${ACCOUNT01_ADDRESS} '/public/flowVault' 123.34" 
    )

# Another array with the signers to use in each transaction. These are always mandatory
transactions_signers=(
    ${ACCOUNT01} 
    ${ACCOUNT02} 
    ${EMULATOR} 
    ${EMULATOR} 
    ${EMULATOR} 
    ${EMULATOR} 
    ${ACCOUNT01} 
    ${EMULATOR}
    )

# echo "Transactions to execute = ${#transactions_to_execute[*]}"
# echo "Transaction arguments = ${#transaction_arguments[*]}"
# echo "Transaction signers = ${#transaction_signers[*]}"

# Validate all arrays at this point
if [ ${#transactions_to_execute[*]} != ${#transaction_arguments[*]} ]; then
    echo "The number of transactions to execute don't match the number of transaction arguments! Cannot continue!"
    set -e
elif [ ${#transaction_to_execute[*]} != ${#transaction_signers[*]} ]; then
    echo "The number of transactions to execute don't match the number of transaction signers! Cannot continue!"
    set -e
elif [ ${#transaction_arguments[*]} != ${#transaction_signers[*]} ]; then
    echo "The number of transaction arguments don't match the number of transaction signers! Cannot continue!"
    set -e
else
    echo "All configuration arrays match. Running batch of transactions"
fi

# The network where the transactions are to be executed. Since its always the same network for all transactions (in principle), in this case is just one variable
NETWORK="emulator"

# All good this far. Run the transactions in a cycle, as you do
for (( i=0; i<${#transactions_to_execute[*]}; i++ ))
do
    transaction_setup="flow transactions send ${TRANSACTIONS_BASE_PATH}${transactions_to_execute[$i]} ${transaction_arguments[$i]} --signer ${transactions_signers[$i]} --network $NETWORK"

    echo "Running $transaction_setup..."
    
    eval $transaction_setup

    echo "Transaction executed correctly"
done
 
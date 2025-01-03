#!/bin/bash

# This script is used to load all accounts configured in a local flow.json into environment variable with the same name (or close to it)
# This simplifies greatly providing the account address as inputs to scripts and transactions, i.e., I want to avoid the annoying copy-paste every time I need to provide one
# NOTE: Because Bash is super picky about allowing subprocesses to define variables in the parent process, I cannot define the variables 'per se' in the script itself. 
# If I run the script 'normally', i.e., using './<script_name>.sh', nothing happens regarding the environment. For that to happen, this script needs to be run with:
#
#   eval "$(./process_accounts.sh)"

# Read the main JSON object into a variable and extract the 'accounts' to a variable (don't need the rest for now)
accounts=$(cat flow.json | jq '.accounts')

# Split the account names, which are used as the main keys in the accounts element, into a dedicated variable (it's going to be a string)
account_names=$(echo $accounts | jq '. | keys')
# Same thing to extract just the addresses from the bigger element
account_addresses=$(echo $accounts | jq '.[] | .address')

# The string returned from the 'keys' feature comes formatted as a Python-style array string, i.e., with '[', ']' and a bunch of other stuff that needs to be processed before attempting to
# convert the string into a bash array. Also, right now, the two strings (names and addresses) don't have the same formatting, so I need to normalise this first.

for account_name in $account_names; do
    # echo $account_name
    echo $accounts | jq --arg arg1 $account_name '.[$arg1]'

    # acct_addr=$(echo $accounts | jq --arg jq_account_name $account_name '.jq_account_name.address')
    # echo $acct_addr
done;

exit 0;

echo "account01: "
echo $accounts | jq '.account01.address'

# Convert the Python-style array string to a Bash style array
# Remove whitespaces
account_names=${account_names// /}

# Replace ',' with a whitespace
account_names=${account_names//,/ }

# Remove the '[' and ']'
account_names=${account_names##[}
account_names=${account_names%]}

# Replace any '-' by '_' because bash does not like variables with '-'
account_names=${account_names//-/_}

# Remove any double quotes from both array strings before continuing
account_names=$(echo $account_names | tr -d '"')
account_addresses=$(echo $account_addresses | tr -d '"')

# The variables are still in string format. I need to change them to proper bash arrays
# Create the empty arrays first
names=()
addresses=()

# And process each word of the string, i.e., element separated by a white space, as a new array item and add it to the proper structure
for name in $account_names; do
    names+=("$name")
done;

for address in $account_addresses; do
    addresses+=("$address")
done;

# Validate that the two arrays have the same length
if [[ ! ${#names[@]} -eq ${#addresses[@]} ]];
then
    echo "The arrays have different sizes!"
    echo "'Names' has "${#names[@]}" elements while 'addresses' has "${#addresses[@]}" elements!"
    echo "Cannot continue!"
    exit 1
fi;

# Doing '${!array_name[@]}' returns the keys of the element, which in the case of a bash array, these are going to be the index value of each element
for i in "${!names[@]}";
do
    # Check if the address string has the '0x' element and add it if not to normalise this whole thing
    current_address=${addresses[$i]}
    if [ ${current_address:0:2} != "0x" ];
    then
        current_address=$(echo "0x"$current_address)
    fi;
    
    # printf "export %s=%s\n" "${names[$i]}" "$current_address"

    # Finally this is ready to export the variables properly
    echo export ${names[$i]}=$current_address
done;


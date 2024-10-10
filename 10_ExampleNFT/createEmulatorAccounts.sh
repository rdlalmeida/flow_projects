#!/bin/bash

# KEYS_OUTPUT=$(flow keys generate)
#echo $KEYS_OUTPUT >> ./keys.txt

KEYS_OUTPUT=$(<keys.txt)

# TODO: Set up a input reading routine to read and validate the number of new accounts to create (min = 1, max = 20)

# Read the JSON object from the configuration file to a variable
FLOW_JSON=$(cat flow.json | jq '.')

# THIS BIT NEEDS TO HAPPEN IN A CYCLE THAT STARTS
# HERE
######################## 0. Set the base element for this exercise at this point
# TODO: Append the cycle number to this name
ACCOUNT_NAME="account" 

######################## 1. Get a pair of asymmetrical encryption keys into variables
# NF = Number of Fields
# FS = Field Separator
# OFS = Output Field Separator
PRIVATE_KEY=$(echo $KEYS_OUTPUT | awk '
    {
        for (i=2; i<NF; i++) {
            if ($(i-2) == "Private" && $(i-1) == "Key") {
                print $i;
                exit;
            }
        }
    }' FS=" " OFS=" "
)

PUBLIC_KEY=$(echo $KEYS_OUTPUT | awk '
    {
        for(i=2; i<NF; i++) {
            if($(i-2) == "Public" && $(i-1) == "Key") {
                print $i;
                exit;
            }
        }
    }' FS=" " OFS=" "
)
echo "Private Key = " $PRIVATE_KEY
echo "Public Key = " $PUBLIC_KEY

######################## 2. Use the Public Key to generate a Flow Emulator account and capture the address to another variable

ACCOUNT_OUTPUT=$(flow accounts create --key $PUBLIC_KEY)

ACCOUNT_ADDRESS=$(echo $ACCOUNT_OUTPUT | awk '
    {
        for (i=1; i<NF; i++) {
            if($(i-1) == "Address") {
                print $i;
                exit;
            }
        }
    }' FS=" " OFS=" "
)

echo "Account address = " $ACCOUNT_ADDRESS

######################## 3. Save the Private key to a file and add it to the .gitignore file
ACCOUNT_FILENAME="$ACCOUNT_NAME.pkey"
echo $PRIVATE_KEY > $ACCOUNT_FILENAME
echo $ACCOUNT_FILENAME >> ./.gitignore

######################## 4. Add the new JSON account element to flow.json

# Add the new JSON account element to the existing 'accounts' element from flow.json and save it back to the same variable, thus updating it
# NOTE: This process depends heavily in the 'jq' command, which allows the bash shell to manipulate JSON objects. If needed, install this command with "sudo apt-get install jq" 
FLOW_JSON=$(echo $FLOW_JSON | jq --arg account_address "$ACCOUNT_ADDRESS" --arg account_name "$ACCOUNT_NAME" --arg key_location "$ACCOUNT_FILENAME" '.accounts += {$account_name: {"address": $account_address, "key": { "type": "file", "location": $key_location}}}')

# AND ENDS HERE

######################## 5. Save the new JSON object with the new accounts back to the flow.json file

echo $FLOW_JSON | jq '.' > flow.json

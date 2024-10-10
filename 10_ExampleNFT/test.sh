#!/bin/bash

FLOW_ACCOUNTS=$(cat flow.json | jq '.')

# echo $FLOW_ACCOUNTS | jq '.'

NEW_ADDRESS="0x12345678"

NEW_VAR=$(echo $FLOW_ACCOUNTS | jq --arg address "$NEW_ADDRESS" '.accounts += { "account02": { "address": $address, "key": { "type": "file", "location": "somePath"}}}')

echo $NEW_VAR | jq '.'
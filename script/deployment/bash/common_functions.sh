#!/bin/bash

set -e

# Read environment variables
source .env

# Get CHAIN_ID automatically using RPC_URL
CHAIN_ID=$(cast chain-id --rpc-url $RPC_URL)
echo "Detected Chain ID: $CHAIN_ID"

# Set config and output directories
CONFIG_DIR="script/config/$CHAIN_ID/42420"
CONFIG_FILE="$CONFIG_DIR/targetContractSetConfig.json"
OUTPUT_FILE="$CONFIG_DIR/targetContractAddresses.json"

# Function to check if a contract is already deployed
is_deployed() {
    local contract_name=$1
    if [ -f "$OUTPUT_FILE" ]; then
        grep -q "\"$contract_name\":" "$OUTPUT_FILE"
        return $?
    fi
    return 1
}

# Function to get deployed address
get_deployed_address() {
    local contract_name=$1
    grep "\"$contract_name\":" "$OUTPUT_FILE" | cut -d '"' -f4
}

# Function to deploy a contract
deploy_contract() {
    local contract_path=$1
    local contract_name=$2
    local constructor_args=${3:-""}
    
    if is_deployed "$contract_name"; then
        echo "$contract_name already deployed, skipping..."
    else
        echo "Deploying $contract_name..."
        local output
        if output=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY $contract_path $constructor_args 2>&1); then
            address=$(echo "$output" | grep "Deployed to" | awk '{print $3}')
            echo "$contract_name deployed to: $address"
            echo "\"$contract_name\": \"$address\"," >> $OUTPUT_FILE
        else
            echo "Failed to deploy $contract_name"
            echo "$output"
            return 1
        fi
    fi
    get_deployed_address "$contract_name"
}

# Function to deploy a proxy contract
deploy_proxy() {
    local contract_path=$1
    local contract_name=$2
    local init_data=$3
    local proxy_admin=$4
    
    if is_deployed "$contract_name"; then
        echo "$contract_name already deployed, skipping..."
    else
        echo "Deploying implementation for $contract_name..."
        if ! deploy_contract $contract_path "${contract_name}Implementation"; then
            echo "Failed to deploy implementation for $contract_name"
            return 1
        fi
        implementation_address=$(get_deployed_address "${contract_name}Implementation")
        
        echo "Deploying proxy for $contract_name..."
        local output
        if output=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY \
            lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy \
            --constructor-args $implementation_address $proxy_admin $init_data 2>&1); then
            address=$(echo "$output" | grep "Deployed to" | awk '{print $3}')
            echo "$contract_name deployed to: $address"
            echo "\"$contract_name\": \"$address\"," >> $OUTPUT_FILE
        else
            echo "Failed to deploy proxy for $contract_name"
            echo "$output"
            return 1
        fi
    fi
    get_deployed_address "$contract_name"
}

# Function to call a contract method
call_contract() {
    local contract_address=$1
    local function_signature=$2
    local private_key=${3:-$PRIVATE_KEY}
    shift 3
    local args="$@"
    
    echo "Calling $function_signature on $contract_address with args $args"
    cast send --rpc-url $RPC_URL --private-key $private_key $contract_address $function_signature $args
}

# Initialize output file if it doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "{" > $OUTPUT_FILE
fi

# Read configuration
CONFIG=$(cat "$CONFIG_FILE")
USE_PRECOMPILED_MODEXP=$(echo $CONFIG | jq -r '.usePrecompiledModexp')
PROXY_ADMIN_OWNER=$(echo $CONFIG | jq -r '.proxyAdminOwner')
OWNER_ADDRESS=$(echo $CONFIG | jq -r '.targetContractsOwner')
EORACLE_CHAIN_ID=$(echo $CONFIG | jq -r '.eoracleChainId')
ALLOWED_SENDERS=$(echo $CONFIG | jq -r '.allowedSenders | join(",")')
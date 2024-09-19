#!/bin/bash

set -e

# Read environment variables
source .env

DEPLOYER_ADDRESS=$(cast wallet address $PRIVATE_KEY)
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
    local constructor_args=${2:-""}
    
    local contract_name=$(basename $contract_path .sol | cut -d':' -f2)
    if is_deployed "$contract_name"; then
        echo "$contract_name already deployed, skipping..."
    else
        echo "Deploying $contract_name..."
        local output
        if output=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY --zksync $contract_path $constructor_args 2>&1); then
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
    local init_data=$2
    local proxy_admin=$3
    
    local contract_name=$(basename $contract_path .sol | cut -d':' -f2)
    local proxy_name="${contract_name}Proxy"
    if is_deployed "$proxy_name"; then
        echo "$proxy_name already deployed, skipping..."
    else
        echo "Deploying implementation for $contract_name..."
        if ! deploy_contract $contract_path; then
            echo "Failed to deploy implementation for $contract_name"
            return 1
        fi
        implementation_address=$(get_deployed_address $contract_name)

        echo "Deploying proxy for $contract_name..."
        local output
        if output=$(forge create --rpc-url $RPC_URL --private-key  $PRIVATE_KEY --zksync\
            lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol:TransparentUpgradeableProxy \
            --constructor-args $implementation_address $proxy_admin $init_data 2>&1); then
            address=$(echo "$output" | grep "Deployed to" | awk '{print $3}')
            echo "$proxy_name deployed to: $address"
            echo "\"$proxy_name\": \"$address\"," >> $OUTPUT_FILE
        else
            echo "Failed to deploy proxy for $contract_name"
            echo "$output"
            return 1
        fi
    fi
    get_deployed_address "$proxy_name"
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

# Deploy BN256G2
if [ "$USE_PRECOMPILED_MODEXP" = true ]; then
    deploy_contract "src/common/BN256G2v1.sol:BN256G2v1"
    BN256G2_ADDRESS=$(get_deployed_address "BN256G2v1")
else
    deploy_contract "src/common/BN256G2.sol:BN256G2"
    BN256G2_ADDRESS=$(get_deployed_address "BN256G2")
fi

# Deploy BLS
deploy_contract "src/common/BLS.sol:BLS"
BLS_ADDRESS=$(get_deployed_address "BLS")

# Deploy EOFeedVerifier
FEED_VERIFIER_INIT=$(cast calldata "initialize(address,address,address,uint256,address[])" \
    $DEPLOYER_ADDRESS $BLS_ADDRESS $BN256G2_ADDRESS $EORACLE_CHAIN_ID [$ALLOWED_SENDERS])
deploy_proxy "src/EOFeedVerifier.sol:EOFeedVerifier" $FEED_VERIFIER_INIT $PROXY_ADMIN_OWNER
FEED_VERIFIER_PROXY=$(get_deployed_address "EOFeedVerifierProxy")

# Deploy EOFeedManager
FEED_MANAGER_INIT=$(cast calldata "initialize(address,address)" $FEED_VERIFIER_PROXY $OWNER_ADDRESS)
deploy_proxy "src/EOFeedManager.sol:EOFeedManager" $FEED_MANAGER_INIT $PROXY_ADMIN_OWNER
FEED_MANAGER_PROXY=$(get_deployed_address "EOFeedManagerProxy")

# Get current owner of EOFeedVerifierProxy
CURRENT_OWNER=$(cast call $FEED_VERIFIER_PROXY "owner()(address)" --rpc-url $RPC_URL)

# Transfer ownership of FeedVerifier only if current owner is different
if [ "$CURRENT_OWNER" != "$OWNER_ADDRESS" ]; then
    call_contract $FEED_VERIFIER_PROXY "setFeedManager(address)" $PRIVATE_KEY $FEED_MANAGER_PROXY
    call_contract $FEED_VERIFIER_PROXY "transferOwnership(address)" $PRIVATE_KEY $OWNER_ADDRESS
fi

# Setup core contracts
SUPPORTED_FEED_IDS=$(echo $CONFIG | jq -r '.supportedFeedIds | join(",")')
SUPPORTED_FEED_BOOLS=$(echo $CONFIG | jq -r '.supportedFeedIds | map(true) | join(",")')

call_contract $FEED_MANAGER_PROXY "setSupportedFeeds(uint16[],bool[])" $OWNER_PRIVATE_KEY [$SUPPORTED_FEED_IDS] [$SUPPORTED_FEED_BOOLS]

PUBLISHERS=$(echo $CONFIG | jq -r '.publishers | join(",")')
PUBLISHERS_BOOLS=$(echo $CONFIG | jq -r '.publishers | map(true) | join(",")')
call_contract $FEED_MANAGER_PROXY "whitelistPublishers(address[],bool[])" $OWNER_PRIVATE_KEY [$PUBLISHERS] [$PUBLISHERS_BOOLS]

# Deploy FeedRegistryAdapter
deploy_contract "src/adapters/EOFeedAdapter.sol:EOFeedAdapter"
FEED_ADAPTER_IMPL=$(get_deployed_address "EOFeedAdapter")
 
FEED_REGISTRY_ADAPTER_INIT=$(cast calldata "initialize(address,address,address)" $FEED_MANAGER_PROXY $FEED_ADAPTER_IMPL $OWNER_ADDRESS)
deploy_proxy "src/adapters/EOFeedRegistryAdapter.sol:EOFeedRegistryAdapter" $FEED_REGISTRY_ADAPTER_INIT $PROXY_ADMIN_OWNER
FEED_REGISTRY_ADAPTER_PROXY=$(get_deployed_address "EOFeedRegistryAdapterProxy")

# Deploy Feeds
echo "\"feeds\": {" >> $OUTPUT_FILE
SUPPORTED_FEEDS_DATA=$(echo $CONFIG | jq -c '.supportedFeedsData[]')
for feed in $SUPPORTED_FEEDS_DATA; do
    FEED_ID=$(echo $feed | jq -r '.feedId')
    EXISTING_FEED=$(cast call $FEED_REGISTRY_ADAPTER_PROXY "getFeedById(uint16)(address)" $FEED_ID --rpc-url $RPC_URL)
    if [ "$EXISTING_FEED" = "0x0000000000000000000000000000000000000000" ]; then
        BASE=$(echo $feed | jq -r '.base')
        QUOTE=$(echo $feed | jq -r '.quote')
        DESCRIPTION=$(echo $feed | jq -r '.description')
        DECIMALS=$(echo $feed | jq -r '.decimals')
        call_contract $FEED_REGISTRY_ADAPTER_PROXY "deployEOFeedAdapter(address,address,uint16,string,uint8,uint256)" $OWNER_PRIVATE_KEY \
            $BASE $QUOTE $FEED_ID $DESCRIPTION $DECIMALS 1
        NEW_FEED=$(cast call $FEED_REGISTRY_ADAPTER_PROXY "getFeedById(uint16)(address)" $FEED_ID --rpc-url $RPC_URL)
        echo "\"$DESCRIPTION\": \"$NEW_FEED\"," >> $OUTPUT_FILE
    else
        echo "Feed with ID $FEED_ID already exists. Skipping deployment."
    fi
done
echo "}" >> "$OUTPUT_FILE"

# Deploy LibDenominations
deploy_contract "src/libraries/Denominations.sol:Denominations"

# Close the output file if it's not properly closed
sed -i -e '$ s/,$//' "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "Deployment completed. Addresses saved to $OUTPUT_FILE"
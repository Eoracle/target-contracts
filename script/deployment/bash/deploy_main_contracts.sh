#!/bin/bash

source script/deployment/bash/common_functions.sh

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
    $OWNER_ADDRESS $BLS_ADDRESS $BN256G2_ADDRESS $EORACLE_CHAIN_ID "[$ALLOWED_SENDERS]")
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
call_contract $FEED_MANAGER_PROXY "setSupportedFeeds(uint16[],bool[])" $OWNER_PRIVATE_KEY "[$SUPPORTED_FEED_IDS]" "[$SUPPORTED_FEED_BOOLS]"

PUBLISHERS=$(echo $CONFIG | jq -r '.publishers | join(",")')
PUBLISHERS_BOOLS=$(echo $CONFIG | jq -r '.publishers | map(true) | join(",")')
call_contract $FEED_MANAGER_PROXY "whitelistPublishers(address[],bool[])" $OWNER_PRIVATE_KEY "[$PUBLISHERS]" "[$PUBLISHERS_BOOLS]"
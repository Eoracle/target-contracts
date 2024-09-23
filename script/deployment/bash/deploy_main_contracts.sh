#!/bin/bash

source script/deployment/bash/common_functions.sh

# Deploy BLS
deploy_contract "src/common/BLS.sol:BLS" "bls"
BLS_ADDRESS=$(get_deployed_address "bls")

# Deploy BN256G2
if [ "$USE_PRECOMPILED_MODEXP" = true ]; then
    deploy_contract "src/common/BN256G2v1.sol:BN256G2v1" "bn256G2"
    BN256G2_ADDRESS=$(get_deployed_address "bn256G2")
else
    deploy_contract "src/common/BN256G2.sol:BN256G2" "bn256G2"
    BN256G2_ADDRESS=$(get_deployed_address "bn256G2")
fi

# Deploy EOFeedVerifier
FEED_VERIFIER_INIT=$(cast calldata "initialize(address,address,address,uint256,address[])" \
    $OWNER_ADDRESS $BLS_ADDRESS $BN256G2_ADDRESS $EORACLE_CHAIN_ID "[$ALLOWED_SENDERS]")
deploy_proxy "src/EOFeedVerifier.sol:EOFeedVerifier" "feedVerifier" $FEED_VERIFIER_INIT $PROXY_ADMIN_OWNER
FEED_VERIFIER_PROXY=$(get_deployed_address "feedVerifier")

# Deploy EOFeedManager
FEED_MANAGER_INIT=$(cast calldata "initialize(address,address)" $FEED_VERIFIER_PROXY $OWNER_ADDRESS)
deploy_proxy "src/EOFeedManager.sol:EOFeedManager" "feedManager" $FEED_MANAGER_INIT $PROXY_ADMIN_OWNER
FEED_MANAGER_PROXY=$(get_deployed_address "feedManager")

call_contract $FEED_VERIFIER_PROXY "setFeedManager(address)" $OWNER_PRIVATE_KEY $FEED_MANAGER_PROXY

# Setup core contracts
SUPPORTED_FEED_IDS=$(echo $CONFIG | jq -r '.supportedFeedIds | join(",")')
SUPPORTED_FEED_BOOLS=$(echo $CONFIG | jq -r '.supportedFeedIds | map(true) | join(",")')
call_contract $FEED_MANAGER_PROXY "setSupportedFeeds(uint16[],bool[])" $OWNER_PRIVATE_KEY "[$SUPPORTED_FEED_IDS]" "[$SUPPORTED_FEED_BOOLS]"

PUBLISHERS=$(echo $CONFIG | jq -r '.publishers | join(",")')
PUBLISHERS_BOOLS=$(echo $CONFIG | jq -r '.publishers | map(true) | join(",")')
call_contract $FEED_MANAGER_PROXY "whitelistPublishers(address[],bool[])" $OWNER_PRIVATE_KEY "[$PUBLISHERS]" "[$PUBLISHERS_BOOLS]"
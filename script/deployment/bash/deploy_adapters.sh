#!/bin/bash

source script/deployment/bash/common_functions.sh

# Deploy FeedRegistryAdapter
deploy_contract "src/adapters/EOFeedAdapter.sol:EOFeedAdapter" "feedAdapterImplementation"
FEED_ADAPTER_IMPL=$(get_deployed_address "feedAdapterImplementation")

FEED_MANAGER_PROXY=$(get_deployed_address "feedManager")
FEED_REGISTRY_ADAPTER_INIT=$(cast calldata "initialize(address,address,address)" $FEED_MANAGER_PROXY $FEED_ADAPTER_IMPL $OWNER_ADDRESS)
deploy_proxy "src/adapters/EOFeedRegistryAdapter.sol:EOFeedRegistryAdapter" "feedRegistryAdapter" $FEED_REGISTRY_ADAPTER_INIT $PROXY_ADMIN_OWNER

echo "Deployment of adapters completed. Addresses saved to $OUTPUT_FILE"
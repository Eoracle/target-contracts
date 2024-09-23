#!/bin/bash

source script/deployment/bash/common_functions.sh

# Deploy FeedRegistryAdapter
deploy_contract "src/adapters/EOFeedAdapter.sol:EOFeedAdapter" "feedAdapterImplementation"
FEED_ADAPTER_IMPL=$(get_deployed_address "feedAdapterImplementation")

FEED_MANAGER_PROXY=$(get_deployed_address "feedManager")
FEED_REGISTRY_ADAPTER_INIT=$(cast calldata "initialize(address,address,address)" $FEED_MANAGER_PROXY $FEED_ADAPTER_IMPL $OWNER_ADDRESS)
deploy_proxy "src/adapters/EOFeedRegistryAdapter.sol:EOFeedRegistryAdapter" "feedRegistryAdapter" $FEED_REGISTRY_ADAPTER_INIT $PROXY_ADMIN_OWNER
FEED_REGISTRY_ADAPTER_PROXY=$(get_deployed_address "feedRegistryAdapter")

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

# Close the output file if it's not properly closed
sed -i -e '$ s/,$//' "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "Deployment of adapters and feeds completed. Addresses saved to $OUTPUT_FILE"
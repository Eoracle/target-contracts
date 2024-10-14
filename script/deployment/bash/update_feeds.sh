#!/bin/bash

source script/deployment/bash/common_functions.sh

FEED_MANAGER_PROXY=$(get_deployed_address "feedManager")

# Update supported feeds
SUPPORTED_FEED_IDS=$(echo $CONFIG | jq -r '.supportedFeedIds | join(",")')
SUPPORTED_FEED_BOOLS=$(echo $CONFIG | jq -r '.supportedFeedIds | map(true) | join(",")')
call_contract $FEED_MANAGER_PROXY "setSupportedFeeds(uint16[],bool[])" $OWNER_PRIVATE_KEY "[$SUPPORTED_FEED_IDS]" "[$SUPPORTED_FEED_BOOLS]"

echo "Deploying feeds..."
bash script/deployment/bash/deploy_feeds.sh

echo "Format output file..."
npx prettier --write $OUTPUT_FILE
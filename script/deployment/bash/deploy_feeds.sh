source script/deployment/bash/common_functions.sh

FEED_REGISTRY_ADAPTER_PROXY=$(get_deployed_address "feedRegistryAdapter")

IS_NEW_FEEDS=0
# Add feeds section if not already present
if ! grep -q "\"feeds\":" "$OUTPUT_FILE"; then
    echo "\"feeds\": {" >> $OUTPUT_FILE
    IS_NEW_FEEDS=1
fi 

# if feeds exist remove two closing braces
if [ $IS_NEW_FEEDS -eq 0 ]; then
    # delete two last lines
    sed -i '' -e '$ d' "$OUTPUT_FILE"
    sed -i '' -e '$ d' "$OUTPUT_FILE"
    # add comma to the end of the file
    echo "," >> "$OUTPUT_FILE"
fi

# Deploy Feeds
SUPPORTED_FEEDS_DATA=$(echo $CONFIG | jq -c '.supportedFeedsData[]')
for feed in $SUPPORTED_FEEDS_DATA; do
    FEED_ID=$(echo $feed | jq -r '.feedId')
    EXISTING_FEED=$(cast call $FEED_REGISTRY_ADAPTER_PROXY "getFeedById(uint16)(address)" $FEED_ID --rpc-url $RPC_URL)
    if [ "$EXISTING_FEED" = "0x0000000000000000000000000000000000000000" ]; then
        BASE=$(echo $feed | jq -r '.base')
        QUOTE=$(echo $feed | jq -r '.quote')
        DESCRIPTION=$(echo $feed | jq -r '.description')
        INPUT_DECIMALS=$(echo $feed | jq -r '.inputDecimals')
        OUTPUT_DECIMALS=$(echo $feed | jq -r '.outputDecimals')
        call_contract $FEED_REGISTRY_ADAPTER_PROXY "deployEOFeedAdapter(address,address,uint16,string,uint8,uint8,uint256)" $OWNER_PRIVATE_KEY \
            $BASE $QUOTE $FEED_ID $DESCRIPTION $INPUT_DECIMALS $OUTPUT_DECIMALS 1
        NEW_FEED=$(cast call $FEED_REGISTRY_ADAPTER_PROXY "getFeedById(uint16)(address)" $FEED_ID --rpc-url $RPC_URL)
        echo "\"$DESCRIPTION\": \"$NEW_FEED\"," >> $OUTPUT_FILE
    else
        echo "Feed with ID $FEED_ID already exists. Skipping deployment."
    fi
done
# Remove last comma
sed -i -e '$ s/,$//' "$OUTPUT_FILE"

echo "}" >> "$OUTPUT_FILE"
echo "}" >> "$OUTPUT_FILE"

echo "Running prettier..."
npx prettier --write $OUTPUT_FILE --ignore-path ''
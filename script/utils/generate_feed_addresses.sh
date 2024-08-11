#!/bin/bash
# This script processes JSON files within a specified directory structure to extract and display information about EOFeedManager and EOFeedAdapter deployments in the documentation.
#
# Example usage:
# 1. From repo's root directory, run `sh script/utils/generate_feed_addresses.sh > docs/deployments.md`
# 2. Copy content docs/deployments.md to documentation

# Define the base directory
base_dir="script/config/"

# Initialize temporary files
feed_manager_file=$(mktemp)
feed_adapter_file=$(mktemp)

# Initialize header for EOFeedManager Deployments table
echo "## EOFeedManager Deployments" > $feed_manager_file
echo "| Network | Address | Supported Symbols |" >> $feed_manager_file
echo "| ------- | ------- | ----------------- |" >> $feed_manager_file

# Initialize header for EOFeedAdapter Deployments table
echo "## EOFeedAdapter Deployments" > $feed_adapter_file
echo "| Network | Symbol | Address |" >> $feed_adapter_file
echo "| ------- | ------ | ------- |" >> $feed_adapter_file

# Fetch chain list data
chain_data=$(curl -s https://chainid.network/chains.json)

# Function to get network name from chain ID
get_network_name() {
  local chain_id=$1
  echo "$chain_data" | jq -r --arg chain_id "$chain_id" '.[] | select(.chainId == ($chain_id | tonumber)) | .name'
}

# Function to extract data from JSON files
extract_data_from_json() {
  local file_path=$1
  local chain_id=$(basename $(dirname $(dirname $file_path)))
  local network=$(get_network_name $chain_id)

  local feed_manager=$(jq -r '.feedManager' $file_path)
  local feeds=$(jq -r '.feeds' $file_path)

  # Append to EOFeedManager Deployments
  local symbols=$(echo $feeds | jq -r 'keys | join(", ")')
  echo "| $network | $feed_manager | $symbols |" >> $feed_manager_file

  # Append to EOFeedAdapter Deployments
  echo $feeds | jq -r 'to_entries[] | "| '"$network"' | \(.key) | \(.value) |"' >> $feed_adapter_file
}

# Walk through the directory structure
find "$base_dir" -path "*/42420/targetContractAddresses.json" | while read file; do
  extract_data_from_json "$file"
done

# Output the tables
cat $feed_manager_file
echo
cat $feed_adapter_file

# Cleanup temporary files
rm $feed_manager_file
rm $feed_adapter_file

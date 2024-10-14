#!/bin/bash

source script/deployment/bash/common_functions.sh

# Load environment variables
source .env

# Get the feedVerifier address from the OUTPUT_FILE
TARGET_VERIFIER_ADDRESS=$(grep "\"feedVerifier\":" "$OUTPUT_FILE" | cut -d '"' -f4)

if [ -z "$TARGET_VERIFIER_ADDRESS" ]; then
    echo "Error: EOFeedVerifierProxy address not found in $OUTPUT_FILE"
    exit 1
fi

echo "Using EOFeedVerifierProxy address: $TARGET_VERIFIER_ADDRESS"

# Get current validator set length
cur_len=$(cast call $ROOT_VERIFIER_ADDRESS "currentValidatorSetLength()" --rpc-url $ROOT_RPC_URL)
cur_len=$((cur_len))

echo "Current validator set length: $cur_len"

# Get current validator set
current_validator_set=""
for ((i=0; i<cur_len; i++)); do
    # Get validator info
    validator_info=$(cast call $ROOT_VERIFIER_ADDRESS "currentValidatorSet(uint256)(address,uint256)" $i --rpc-url $ROOT_RPC_URL)
    
    address=$(echo $validator_info | awk '{print $1}')
    voting_power=$(echo $validator_info | awk '{print $2}')
    
    # Calculate storage slot for BLS key
    slot=$(cast keccak $(cast abi-encode "f(uint256,uint256)" $i 9))
    # Get BLS key from storage
    bls_key=""
    for j in {1..4}; do
        storage_slot=$(echo "obase=16; ibase=16; $(echo ${slot#0x} | tr '[:lower:]' '[:upper:]') + $j" | bc)
        storage_slot="0x$storage_slot"
        bls_key_part=$(cast storage $ROOT_VERIFIER_ADDRESS $storage_slot --rpc-url $ROOT_RPC_URL)
        bls_key+="$bls_key_part,"
    done
    bls_key=$(echo $bls_key | sed 's/,$//')
    
    current_validator_set+="($address,[$bls_key],$voting_power),"
done
current_validator_set+=""

current_validator_set=$(echo $current_validator_set | sed 's/,$//')
echo "Current validator set:"
echo "$current_validator_set"

# Prepare the ABI-encoded function call data
function_signature="setNewValidatorSet((address,uint256[4],uint256)[])"
call_data=$(cast calldata "$function_signature" "[$current_validator_set]")

# Send transaction using cast
echo "Setting new validator set..."
tx_hash=$(cast send --private-key $OWNER_PRIVATE_KEY --rpc-url $RPC_URL $TARGET_VERIFIER_ADDRESS $call_data)

echo "Transaction sent: $tx_hash"

echo "Script completed successfully"
#!/bin/bash

# Check if filename argument is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

# Input filename
filename=$1

# Loop through each line in the file
while IFS= read -r line; do
    # Check if line starts with 'error '
    if [[ $line == error* ]]; then
        # Remove 'error ' prefix and ';' suffix
        error=$(echo "$line" | sed -e 's/^error //' -e 's/;$//')

        # Run `cast sig` command with the processed error message
        output=$(cast sig "$error")
        
        # Extract the hash (signature) from the output
        signature=$(echo "$output" | awk '{print $1}')

        # Print the signature (hash) and the original error message
        echo "signature                    error"
        echo "$signature              $error"
        echo ""
    fi
done < "$filename"
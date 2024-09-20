#!/bin/bash

set -e

echo "Starting deployment process..."

echo "Deploying main contracts..."
# bash script/deployment/bash/deploy_main_contracts.sh

echo "Deploying adapters and feeds..."
# bash script/deployment/bash/deploy_adapters_and_feeds.sh

echo "Setting validators..."
bash script/deployment/bash/setValidators.sh

echo "All deployments completed successfully."
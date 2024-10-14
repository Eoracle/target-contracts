#!/bin/bash

set -e

echo "Starting deployment process..."

echo "Deploying main contracts..."
bash script/deployment/bash/deploy_main_contracts.sh

echo "Deploying adapters..."
bash script/deployment/bash/deploy_adapters.sh

echo "Deploying feeds..."
bash script/deployment/bash/deploy_feeds.sh

echo "Setting validators..."
bash script/deployment/bash/set_validators.sh

echo "All deployments completed successfully."
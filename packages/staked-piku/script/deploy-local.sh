#!/bin/bash

# Start Anvil in the background
echo "Starting Anvil..."
anvil --block-time 12 &
ANVIL_PID=$!

# Wait for Anvil to start
sleep 2

# Deploy the contracts
echo "Deploying contracts..."
forge script script/LocalDeployment.s.sol:LocalDeployment --fork-url http://localhost:8545 --broadcast -vvv

# Keep Anvil running, press Ctrl+C to stop
echo "Deployment complete. Press Ctrl+C to stop Anvil..."
wait $ANVIL_PID 
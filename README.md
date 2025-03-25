# Staked PIKU Project

This monorepo contains three packages for the Staked PIKU project:

## Project Structure

### 1. `packages/staked-piku`
The main package containing the StakedPikuV2 contract and PIKU token contract. This package is built using Foundry and handles the core staking functionality.

### 2. `packages/merkle-distribution`
Contains the CumulativeMerkleDrop contract for distributing PIKU tokens via merkle proofs. Built using Hardhat and depends on the PIKU token contract address from the staked-piku deployment.

### 3. `packages/shared-abi`
A shared package that consolidates ABIs and contract addresses from all contracts across different networks. This package is automatically generated and updated when contracts are deployed.

## Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd stakedPiku
```

2. Install dependencies:
```bash
yarn install
```

3. Set up environment files:
```bash
# For staked-piku package
cp packages/staked-piku/.env.example packages/staked-piku/.env

# For merkle-distribution package
cp packages/merkle-distribution/.env.example packages/merkle-distribution/.env
```

Configure the following environment variables in both .env files:
- `SEPOLIA_RPC_URL`: RPC URL for Sepolia testnet
- `MAINNET_RPC_URL`: RPC URL for Ethereum mainnet
- `PRIVATE_KEY`: Your wallet's private key for deployment
- `ETHERSCAN_API_KEY`: Your Etherscan API key for contract verification

Configure the additional variables for the staked-piku .env files
- `PIKU_OWNER_ADDRESS`: Address of the owner of the PIKU contract
- `STAKED_PIKU_OWNER_ADDRESS`: Address of the owner of the StakedPiku contract
- `REWARDER_ADDRESS`: Address of the rewarder for the StakedPiku contract

4. Install Foundry (required for staked-piku package):
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Development Commands

### Build
Build all packages:
```bash
yarn build
```

### Clean
Clean all build artifacts:
```bash
yarn clean
```

## Deployment Process

### 1. Deploy Staked PIKU (Required First)
The StakedPikuV2 and PIKU contracts must be deployed first as the merkle distribution depends on the PIKU token address.

```bash
# Deploy to Sepolia testnet
yarn deploy:staked-piku --rpc-url sepolia

# Deploy to mainnet
yarn deploy:staked-piku --rpc-url mainnet
```

After deployment, note down the PIKU token contract address as it will be needed for the merkle distribution deployment.

### 2. Deploy Merkle Distribution
Once the PIKU token is deployed, you can deploy the merkle distribution contract:

```bash
# Deploy normal merkle distribution to Sepolia
yarn deploy:merkle-drop --network sepolia --t <token_address>

# Deploy normal merkle distribution to mainnet
yarn deploy:merkle-drop --network mainnet --t <token_address>

# Deploy transfer owner merkle distribution to Sepolia
yarn deploy:merkle-drop:withTransferOwner --network sepolia --t <token_address> --o <new_owner_address>

# Deploy transfer owner merkle distribution to mainnet
yarn deploy:merkle-drop:withTransferOwner --network mainnet --t <token_address> --o <new_owner_address>
```

### 3. Generate Shared ABIs
After deployment, generate the shared ABIs and addresses:

```bash
yarn generate-abis
```

This will:
- Extract ABIs from the compiled contracts
- Extract contract addresses from deployment files
- Update the shared-abi package with the latest information

## Testing

Run tests for all packages:
```bash
yarn test
```

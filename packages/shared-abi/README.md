# Shared ABI Package

This package contains ABIs and contract addresses for the StakedPiku project.

## Available ABIs

- `StakedPikuV2.json` - The ABI for the StakedPikuV2 contract
- `PIKU.json` - The ABI for the PIKU token contract
- `CumulativeMerkleDrop.json` - The ABI for the CumulativeMerkleDrop contract (merkle distribution)

## Usage

### Importing ABIs

```js
// Import all ABIs
const abis = require('shared-abi');
const stakedPikuV2Abi = abis.StakedPikuV2;
const pikuAbi = abis.PIKU;
const cumulativeMerkleDropAbi = abis.CumulativeMerkleDrop;

// Use in ethers.js
const contract = new ethers.Contract(address, stakedPikuV2Abi, provider);
```

### Importing Contract Addresses

```js
// Import all addresses
const addresses = require('shared-abi/addresses');
const stakedPikuV2Address = addresses.StakedPikuV2["11155111"]; // For Sepolia network
const pikuAddress = addresses.PIKU["11155111"]; // For Sepolia network
const cumulativeMerkleDropAddress = addresses.CumulativeMerkleDrop["11155111"]; // For Sepolia network
```

## Updating ABIs

The ABIs are automatically generated from the compiled contracts. To update them, run:

```bash
npm run generate-abis
```

This will:
1. Extract the ABIs from the compiled contracts in the `staked-piku` package
2. Extract the CumulativeMerkleDrop ABI from the merkle-distribution deployments
3. Extract contract addresses from all deployment files across multiple networks
4. Save them to the `abis` directory 
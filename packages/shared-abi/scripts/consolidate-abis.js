const fs = require('fs-extra');
const path = require('path');
const { glob } = require('glob');

async function consolidateAbis() {
  try {
    const consolidatedAbiDir = path.resolve(__dirname, '../abis');
    const packagesDir = path.resolve(__dirname, '../..');
    
    // Ensure directories exist
    await fs.ensureDir(consolidatedAbiDir);

    // Get StakedPikuV2 ABI
    const stakedPikuV2SourcePath = path.join(packagesDir, 'staked-piku/out/StakedPikuV2.sol/StakedPikuV2.json');
    const stakedPikuV2DestPath = path.join(consolidatedAbiDir, 'StakedPikuV2.json');
    
    if (await fs.pathExists(stakedPikuV2SourcePath)) {
      const stakedPikuV2Json = await fs.readJson(stakedPikuV2SourcePath);
      await fs.writeJson(stakedPikuV2DestPath, stakedPikuV2Json.abi, { spaces: 2 });
      console.log('Copied StakedPikuV2 ABI');
    } else {
      console.error('StakedPikuV2 ABI source file not found');
    }

    // Get PIKU ABI
    const pikuSourcePath = path.join(packagesDir, 'staked-piku/out/PIKU.sol/PIKU.json');
    const pikuDestPath = path.join(consolidatedAbiDir, 'PIKU.json');
    
    if (await fs.pathExists(pikuSourcePath)) {
      const pikuJson = await fs.readJson(pikuSourcePath);
      await fs.writeJson(pikuDestPath, pikuJson.abi, { spaces: 2 });
      console.log('Copied PIKU ABI');
    } else {
      console.error('PIKU ABI source file not found');
    }

    // Initialize addresses object to store all contract addresses across networks
    const addresses = {
      StakedPikuV2: {},
      PIKU: {},
      CumulativeMerkleDrop: {}
    };

    // Initialize ABIs that may be extracted from deployment files
    const extractedAbis = {
      CumulativeMerkleDrop: null
    };

    // 1. Check Forge broadcast directories 
    const broadcastDir = path.join(packagesDir, 'staked-piku/broadcast');
    if (await fs.pathExists(broadcastDir)) {
      // Get all deployment script directories
      const scriptDirs = await fs.readdir(broadcastDir);
      
      for (const scriptDir of scriptDirs) {
        const scriptPath = path.join(broadcastDir, scriptDir);
        if ((await fs.stat(scriptPath)).isDirectory()) {
          // Get all network directories within this script
          const networkDirs = await fs.readdir(scriptPath);
          
          for (const networkDir of networkDirs) {
            const networkPath = path.join(scriptPath, networkDir);
            if ((await fs.stat(networkPath)).isDirectory()) {
              const chainId = networkDir; // The directory name is the chain ID
              const latestDeployPath = path.join(networkPath, 'run-latest.json');
              
              if (await fs.pathExists(latestDeployPath)) {
                try {
                  const deployment = await fs.readJson(latestDeployPath);
                  
                  // Extract contract addresses
                  for (const tx of deployment.transactions || []) {
                    if (tx.contractName === 'StakedPikuV2') {
                      addresses.StakedPikuV2[chainId] = tx.contractAddress;
                      console.log(`Found StakedPikuV2 address for network ${chainId}: ${tx.contractAddress}`);
                    } else if (tx.contractName === 'PIKU') {
                      addresses.PIKU[chainId] = tx.contractAddress;
                      console.log(`Found PIKU address for network ${chainId}: ${tx.contractAddress}`);
                    } else if (tx.contractName === 'CumulativeMerkleDrop') {
                      addresses.CumulativeMerkleDrop[chainId] = tx.contractAddress;
                      console.log(`Found CumulativeMerkleDrop address for network ${chainId}: ${tx.contractAddress}`);
                    }
                  }
                } catch (error) {
                  console.error(`Error processing deployment at ${latestDeployPath}:`, error.message);
                }
              }
            }
          }
        }
      }
    }

    // 2. Check Hardhat deployments directories (as used in merkle-distribution)
    const deploymentsDir = path.join(packagesDir, 'staked-piku/deployments');
    if (await fs.pathExists(deploymentsDir)) {
      // Get all network directories
      const networkDirs = await fs.readdir(deploymentsDir);
      
      for (const networkDir of networkDirs) {
        const networkPath = path.join(deploymentsDir, networkDir);
        if ((await fs.stat(networkPath)).isDirectory()) {
          // Read chainId file if it exists
          let chainId = networkDir; // Default to directory name
          const chainIdPath = path.join(networkPath, '.chainId');
          
          if (await fs.pathExists(chainIdPath)) {
            try {
              chainId = (await fs.readFile(chainIdPath, 'utf8')).trim();
            } catch (error) {
              console.error(`Error reading chainId from ${chainIdPath}:`, error.message);
            }
          }
          
          // Look for contract deployment files
          const stakedPikuPath = path.join(networkPath, 'StakedPikuV2.json');
          const pikuPath = path.join(networkPath, 'PIKU.json');
          const merklePath = path.join(networkPath, 'CumulativeMerkleDrop.json');
          
          if (await fs.pathExists(stakedPikuPath)) {
            try {
              const deployment = await fs.readJson(stakedPikuPath);
              if (deployment.address) {
                addresses.StakedPikuV2[chainId] = deployment.address;
                console.log(`Found StakedPikuV2 address for network ${networkDir} (${chainId}): ${deployment.address}`);
              }
            } catch (error) {
              console.error(`Error processing deployment at ${stakedPikuPath}:`, error.message);
            }
          }
          
          if (await fs.pathExists(pikuPath)) {
            try {
              const deployment = await fs.readJson(pikuPath);
              if (deployment.address) {
                addresses.PIKU[chainId] = deployment.address;
                console.log(`Found PIKU address for network ${networkDir} (${chainId}): ${deployment.address}`);
              }
            } catch (error) {
              console.error(`Error processing deployment at ${pikuPath}:`, error.message);
            }
          }
          
          if (await fs.pathExists(merklePath)) {
            try {
              const deployment = await fs.readJson(merklePath);
              if (deployment.address) {
                addresses.CumulativeMerkleDrop[chainId] = deployment.address;
                console.log(`Found CumulativeMerkleDrop address for network ${networkDir} (${chainId}): ${deployment.address}`);
              }
              if (deployment.abi && !extractedAbis.CumulativeMerkleDrop) {
                extractedAbis.CumulativeMerkleDrop = deployment.abi;
                console.log(`Extracted CumulativeMerkleDrop ABI from ${networkDir} deployment`);
              }
            } catch (error) {
              console.error(`Error processing deployment at ${merklePath}:`, error.message);
            }
          }
        }
      }
    }

    // 3. Also check merkle-distribution deployments
    const merkleDeploymentsDir = path.join(packagesDir, 'merkle-distribution/deployments');
    if (await fs.pathExists(merkleDeploymentsDir)) {
      // Get all network directories
      const networkDirs = await fs.readdir(merkleDeploymentsDir);
      
      for (const networkDir of networkDirs) {
        const networkPath = path.join(merkleDeploymentsDir, networkDir);
        if ((await fs.stat(networkPath)).isDirectory()) {
          // Read chainId file if it exists
          let chainId = networkDir; // Default to directory name
          const chainIdPath = path.join(networkPath, '.chainId');
          
          if (await fs.pathExists(chainIdPath)) {
            try {
              chainId = (await fs.readFile(chainIdPath, 'utf8')).trim();
            } catch (error) {
              console.error(`Error reading chainId from ${chainIdPath}:`, error.message);
            }
          }
          
          // Look for contract deployment files
          const stakedPikuPath = path.join(networkPath, 'StakedPikuV2.json');
          const pikuPath = path.join(networkPath, 'PIKU.json');
          const merklePath = path.join(networkPath, 'CumulativeMerkleDrop.json');
          
          if (await fs.pathExists(stakedPikuPath)) {
            try {
              const deployment = await fs.readJson(stakedPikuPath);
              if (deployment.address) {
                addresses.StakedPikuV2[chainId] = deployment.address;
                console.log(`Found StakedPikuV2 address for network ${networkDir} (${chainId}): ${deployment.address}`);
              }
            } catch (error) {
              console.error(`Error processing deployment at ${stakedPikuPath}:`, error.message);
            }
          }
          
          if (await fs.pathExists(pikuPath)) {
            try {
              const deployment = await fs.readJson(pikuPath);
              if (deployment.address) {
                addresses.PIKU[chainId] = deployment.address;
                console.log(`Found PIKU address for network ${networkDir} (${chainId}): ${deployment.address}`);
              }
            } catch (error) {
              console.error(`Error processing deployment at ${pikuPath}:`, error.message);
            }
          }
          
          if (await fs.pathExists(merklePath)) {
            try {
              const deployment = await fs.readJson(merklePath);
              if (deployment.address) {
                addresses.CumulativeMerkleDrop[chainId] = deployment.address;
                console.log(`Found CumulativeMerkleDrop address for network ${networkDir} (${chainId}): ${deployment.address}`);
              }
              if (deployment.abi && !extractedAbis.CumulativeMerkleDrop) {
                extractedAbis.CumulativeMerkleDrop = deployment.abi;
                console.log(`Extracted CumulativeMerkleDrop ABI from ${networkDir} deployment`);
              }
            } catch (error) {
              console.error(`Error processing deployment at ${merklePath}:`, error.message);
            }
          }
        }
      }
    }

    // Save extracted ABIs
    for (const [contractName, abi] of Object.entries(extractedAbis)) {
      if (abi) {
        const abiPath = path.join(consolidatedAbiDir, `${contractName}.json`);
        await fs.writeJson(abiPath, abi, { spaces: 2 });
        console.log(`Saved ${contractName} ABI`);
      } else {
        console.log(`No ABI found for ${contractName}`);
      }
    }

    // Write address files
    for (const [contractName, addressData] of Object.entries(addresses)) {
      // Skip if no addresses found
      if (Object.keys(addressData).length === 0) {
        console.log(`No addresses found for ${contractName}`);
        continue;
      }
      
      const addressFilePath = path.join(consolidatedAbiDir, `${contractName}.address.json`);
      
      // If file exists, merge with existing data to prevent overwriting
      let finalAddressData = {};
      if (await fs.pathExists(addressFilePath)) {
        try {
          finalAddressData = await fs.readJson(addressFilePath);
        } catch (error) {
          console.error(`Error reading existing address file ${addressFilePath}:`, error.message);
        }
      }
      
      // Merge with new data (new addresses will override existing ones)
      finalAddressData = { ...finalAddressData, ...addressData };
      
      await fs.writeJson(addressFilePath, finalAddressData, { spaces: 2 });
      console.log(`Created/updated address file for ${contractName} with ${Object.keys(finalAddressData).length} networks`);
    }
    
    console.log('ABIs consolidated successfully');
  } catch (error) {
    console.error('Error consolidating ABIs:', error);
    process.exit(1);
  }
}

consolidateAbis();
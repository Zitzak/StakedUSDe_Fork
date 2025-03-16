const fs = require('fs-extra');
const path = require('path');
const { glob } = require('glob');

async function generateAbis() {
  try {
    const outDir = path.resolve(__dirname, '../out');
    const abiDir = path.resolve(__dirname, '../../../packages/shared-abi/abis/foundry');
    
    // Ensure the ABI directory exists
    await fs.ensureDir(abiDir);
    
    // Find all contract JSON files in the out directory
    const files = await glob('**/*.json', { cwd: outDir });
    
    for (const file of files) {
      // Skip if it's not a contract file
      if (!file.includes('/')) continue;
      
      const filePath = path.join(outDir, file);
      const contractData = await fs.readJson(filePath);
      
      // Extract the contract name
      const contractName = path.basename(file, '.json');
      
      // Only process if it has an ABI
      if (contractData.abi) {
        // Create a JSON file with just the ABI
        const abiFile = path.join(abiDir, `${contractName}.json`);
        await fs.writeJson(abiFile, contractData.abi, { spaces: 2 });
        console.log(`Generated ABI for ${contractName}`);
      }
    }
    
    console.log('Foundry ABIs generated successfully');
  } catch (error) {
    console.error('Error generating ABIs:', error);
    process.exit(1);
  }
}

generateAbis();
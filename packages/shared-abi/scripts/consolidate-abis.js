const fs = require('fs-extra');
const path = require('path');
const { glob } = require('glob');

async function consolidateAbis() {
  try {
    const pikuAbiDir = path.resolve(__dirname, '../abis/piku');
    const merkleAbiDir = path.resolve(__dirname, '../abis/merkle');
    const consolidatedAbiDir = path.resolve(__dirname, '../abis');
    
    // Ensure directories exist
    await fs.ensureDir(pikuAbiDir);
    await fs.ensureDir(merkleAbiDir);
    
    // Process StakedPiku ABIs
    const pikuFiles = await glob('*.json', { cwd: pikuAbiDir });
    for (const file of pikuFiles) {
      const filePath = path.join(pikuAbiDir, file);
      const destPath = path.join(consolidatedAbiDir, file);
      
      // Copy to consolidated directory
      await fs.copy(filePath, destPath, { overwrite: true });
      console.log(`Copied StakedPiku ABI: ${file}`);
    }
    
    // Process Merkle ABIs
    const merkleFiles = await glob('*.json', { cwd: merkleAbiDir });
    for (const file of merkleFiles) {
      const filePath = path.join(merkleAbiDir, file);
      const destPath = path.join(consolidatedAbiDir, file);
      
      // Check if file already exists (from StakedPiku)
      if (await fs.pathExists(destPath)) {
        console.log(`Skipping duplicate ABI: ${file} (already exists from StakedPiku)`);
      } else {
        // Copy to consolidated directory
        await fs.copy(filePath, destPath);
        console.log(`Copied Merkle ABI: ${file}`);
      }
    }
    
    console.log('ABIs consolidated successfully');
  } catch (error) {
    console.error('Error consolidating ABIs:', error);
    process.exit(1);
  }
}

consolidateAbis();
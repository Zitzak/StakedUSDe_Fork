const fs = require('fs');
const path = require('path');

// Dynamically export all ABIs
const abiPath = path.join(__dirname, 'abis');
const abiFiles = fs.readdirSync(abiPath).filter(file => 
  file.endsWith('.json') && !fs.statSync(path.join(abiPath, file)).isDirectory()
);

const abis = {};

for (const file of abiFiles) {
  const contractName = path.basename(file, '.json');
  abis[contractName] = require(path.join(abiPath, file));
}

module.exports = abis;
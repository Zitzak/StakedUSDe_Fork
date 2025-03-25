const fs = require('fs');
const path = require('path');

// Dynamically export all addresses
const abiPath = path.join(__dirname, 'abis');
const addressFiles = fs.readdirSync(abiPath).filter(file => 
  file.endsWith('.address.json') && !fs.statSync(path.join(abiPath, file)).isDirectory()
);

const addresses = {};

for (const file of addressFiles) {
  const contractName = path.basename(file, '.address.json');
  addresses[contractName] = require(path.join(abiPath, file));
}

module.exports = addresses; 
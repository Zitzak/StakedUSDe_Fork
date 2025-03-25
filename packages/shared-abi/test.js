// Test script to verify shared-abi functionality
const abis = require('./index');
const addresses = require('./addresses');

console.log('=== Available ABIs ===');
console.log(Object.keys(abis));

console.log('\n=== Available Addresses ===');
for (const [contractName, networkAddresses] of Object.entries(addresses)) {
  console.log(`${contractName}:`);
  for (const [network, address] of Object.entries(networkAddresses)) {
    console.log(`  ${network}: ${address}`);
  }
}

// Verify ABI structure for StakedPikuV2
console.log('\n=== StakedPikuV2 ABI Structure ===');
console.log(`Number of functions/events: ${abis.StakedPikuV2.length}`);
console.log('First 3 entries:');
console.log(JSON.stringify(abis.StakedPikuV2.slice(0, 3), null, 2));

// Verify ABI structure for PIKU
console.log('\n=== PIKU ABI Structure ===');
console.log(`Number of functions/events: ${abis.PIKU.length}`);
console.log('First 3 entries:');
console.log(JSON.stringify(abis.PIKU.slice(0, 3), null, 2));

// Verify ABI structure for CumulativeMerkleDrop
console.log('\n=== CumulativeMerkleDrop ABI Structure ===');
console.log(`Number of functions/events: ${abis.CumulativeMerkleDrop.length}`);
console.log('First 3 entries:');
console.log(JSON.stringify(abis.CumulativeMerkleDrop.slice(0, 3), null, 2)); 
const hre = require('hardhat');
const { getChainId } = hre;
const { deployAndGetContract } = require('@1inch/solidity-utils');

module.exports = async ({ deployments, getNamedAccounts, newOwner, tokenAddress }) => {
    console.log('running deploy script');
    console.log('network id ', await getChainId());

    const { deployer } = await getNamedAccounts();

    // Token address
    // Must be replaced with real value
    const args = [tokenAddress];
    const maxFeePerGas = 1e11;
    const maxPriorityFeePerGas = 2e9;
    

    const cumulativeMerkleDrop = await deployAndGetContract({
        contractName: 'CumulativeMerkleDrop',
        constructorArgs: args,
        deployments,
        deployer,
    });

    const txn = await cumulativeMerkleDrop.transferOwnership(
        newOwner,
        {
            maxFeePerGas,
            maxPriorityFeePerGas,
        },
    );
    await txn.wait();

    console.log('CumulativeMerkleDrop deployed to:', await cumulativeMerkleDrop.getAddress(), 'and owner transferred to:', deployer);
};

module.exports.skip = async () => true;

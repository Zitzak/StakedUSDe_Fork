// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "contracts/stakedPiku/StakedUSDeV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock USDe token for local testing
contract MockUSDe is ERC20 {
    constructor() ERC20("Mock USDe", "USDe") {
        _mint(msg.sender, 1000000 * 10**18); // Mint 1M tokens
    }
}

contract LocalDeployment is Script {
    function run() public {
        // Use the first test account from Anvil
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy mock USDe token
        MockUSDe mockUSDe = new MockUSDe();
        console.log("Mock USDe deployed to:", address(mockUSDe));
        
        // Deploy StakedUSDeV2
        StakedUSDeV2 stakedUSDe = new StakedUSDeV2(
            IERC20(address(mockUSDe)),
            deployer, // rewarder
            deployer  // owner
        );
        console.log("StakedUSDeV2 deployed to:", address(stakedUSDe));
        
        // Approve staking contract to spend USDe
        mockUSDe.approve(address(stakedUSDe), type(uint256).max);
        
        vm.stopBroadcast();
    }
} 
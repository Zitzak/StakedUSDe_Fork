// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "contracts/stakedPiku/StakedPikuV2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock PIKU token for local testing
contract MockPiku is ERC20 {
    constructor() ERC20("Mock PIKU", "PIKU") {
        _mint(msg.sender, 1000000 * 10**18); // Mint 1M tokens
    }
}

contract LocalDeployment is Script {
    function run() public {
        // Use the first test account from Anvil
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy mock PIKU token
        MockPiku mockPiku = new MockPiku();
        console.log("Mock PIKU deployed to:", address(mockPiku));
        
        // Deploy StakedPikuV2
        StakedPikuV2 stakedPiku = new StakedPikuV2(
            IERC20(address(mockPiku)),
            deployer, // rewarder
            deployer  // owner
        );
        console.log("StakedPikuV2 deployed to:", address(stakedPiku));
        
        // Approve staking contract to spend PIKU
        mockPiku.approve(address(stakedPiku), type(uint256).max);
        
        vm.stopBroadcast();
    }
} 
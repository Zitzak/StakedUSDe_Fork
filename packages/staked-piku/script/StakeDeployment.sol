// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import 'forge-std/Script.sol';
import 'contracts/stakedPiku/StakedPikuV2.sol';
import 'contracts/token/PIKU.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

contract StakeDeployment is Script {
    // update accordingly in the .env file
    address public ownerPikuToken = vm.envAddress('PIKU_OWNER_ADDRESS');
    address public ownerStakedPiku = vm.envAddress('STAKED_PIKU_OWNER_ADDRESS');
    address public rewarder = vm.envAddress('REWARDER_ADDRESS');

    function run() public virtual {
        uint256 ownerPrivateKey = uint256(vm.envBytes32('PRIVATE_KEY'));
        vm.startBroadcast(ownerPrivateKey);

        // Deploy PIKU token first
        PIKU pikuToken = new PIKU(owner);
        console.log('=====> PIKU token deployed ....');
        console.log('PIKU Token Address                   : %s', address(pikuToken));

        // Deploy StakedPikuV2
        StakedPikuV2 stakedPiku = new StakedPikuV2(IERC20(address(pikuToken)), rewarder, owner);
        console.log('=====> StakedPikuV2 deployed ....');
        console.log('StakedPikuV2 Address                 : %s', address(stakedPiku));

        vm.stopBroadcast();
    }
}
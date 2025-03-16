// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import 'forge-std/Script.sol';
import 'contracts/stakedPiku/StakedUSDeV2.sol';
import 'contracts/token/USDe.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';

contract StakeDeployment is Script {
    // // update accordingly - this will be the admin/owner of both contracts
    // address public owner = address(0x2eAA473e2Efb22ba86E76352c19Ec9666984D10C);
    // address public rewarder = address(0x2eAA473e2Efb22ba86E76352c19Ec9666984D10C);

    // function run() public virtual {
    //     uint256 ownerPrivateKey = uint256(vm.envBytes32('PRIVATE_KEY'));
    //     vm.startBroadcast(ownerPrivateKey);

    //     // Deploy USDe token first
    //     USDe usdeToken = new USDe(owner);
    //     console.log('=====> USDe token deployed ....');
    //     console.log('USDe Token Address                   : %s', address(usdeToken));

    //     // Deploy StakedUSDeV2
    //     StakedUSDeV2 stakedUSDe = new StakedUSDeV2(IERC20(address(usdeToken)), rewarder, owner);
    //     console.log('=====> StakedUSDeV2 deployed ....');
    //     console.log('StakedUSDeV2 Address                 : %s', address(stakedUSDe));

    //     vm.stopBroadcast();
    // }
}
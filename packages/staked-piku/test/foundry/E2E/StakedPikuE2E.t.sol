// // // SPDX-License-Identifier: AGPL-3.0-only
// pragma solidity ^0.8.0;

// import {console2} from "forge-std/console2.sol";

// import {Test} from "forge-std/Test.sol";

// import {StakedUSDeV2} from "../../../contracts/StakedUSDeV2.sol";
// import {USDe} from "../../../contracts/USDe.sol";



// contract StakedPikuE2E is Test {
//     StakedUSDeV2 stakedPiku;
//     USDe pikuToken;

//     address constant PIKU_ADMIN = makeAddr("PIKU_ADMIN");
//     address constant REWARDER = makeAddr("REWARDER");

//     address constant STAKER_1 = makeAddr("STAKER_1");
//     address constant STAKER_2 = makeAddr("STAKER_2");

//     address constant DELEGATE_1 = makeAddr("DELEGATE_1");
//     address constant DELEGATE_2 = makeAddr("DELEGATE_2");
//     address constant DELEGATE_3 = makeAddr("DELEGATE_3");

//     function setUp() public {
//         // Init piku token
//         pikuToken = new USDe(address(this));

//         pikuToken.setMinter(address(this));

//         // Init staked piku
//         stakedPiku = new StakedUSDeV2(pikuToken, REWARDER, PIKU_ADMIN);
//     }

//     function lifecycle() public {}
// }
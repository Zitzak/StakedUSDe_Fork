// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/* solhint-disable func-name-mixedcase  */
/* solhint-disable private-vars-leading-underscore  */

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import {SigUtils} from "forge-std/SigUtils.sol";

import "contracts/token/PIKU.sol";
import "contracts/stakedPiku/StakedPikuV2.sol";
import "contracts/interfaces/IPiku.sol";
import "contracts/interfaces/IERC20Events.sol";
import "test/foundry/stakedPiku/StakedPiku.t.sol";

/// @dev Run all StakedPikuV1 tests against StakedPikuV2 with cooldown duration zero, to ensure backwards compatibility
contract StakedPikuV2CooldownDisabledTest is StakedPikuTest {
  StakedPikuV2 stakedPIKUV2;

  function setUp() public virtual override {
    pikuToken = new PIKU(address(this));

    alice = vm.addr(0xB44DE);
    bob = vm.addr(0x1DE);
    greg = vm.addr(0x6ED);
    owner = vm.addr(0xA11CE);
    rewarder = vm.addr(0x1DEA);
    vm.label(alice, "alice");
    vm.label(bob, "bob");
    vm.label(greg, "greg");
    vm.label(owner, "owner");
    vm.label(rewarder, "rewarder");

    vm.startPrank(owner);
    stakedPiku = new StakedPikuV2(IPiku(address(pikuToken)), rewarder, owner);
    stakedPIKUV2 = StakedPikuV2(address(stakedPiku));

    // Disable cooldown and unstake methods, enable StakedPikuV1 methods
    stakedPIKUV2.setCooldownDuration(0);
    vm.stopPrank();

    sigUtilsPiku = new SigUtils(pikuToken.DOMAIN_SEPARATOR());
    sigUtilsStakedPiku = new SigUtils(stakedPiku.DOMAIN_SEPARATOR());

    pikuToken.setMinter(address(this));
  }

  function test_cooldownShares_fails_cooldownDuration_zero() external {
    vm.expectRevert(IStakedPiku.OperationNotAllowed.selector);
    stakedPIKUV2.cooldownShares(0, address(0));
  }

  function test_cooldownAssets_fails_cooldownDuration_zero() external {
    vm.expectRevert(IStakedPiku.OperationNotAllowed.selector);
    stakedPIKUV2.cooldownAssets(0, address(0));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import {SigUtils} from "forge-std/SigUtils.sol";

import "contracts/token/PIKU.sol";
import "contracts/stakedPiku/StakedPiku.sol";
import "contracts/interfaces/IStakedPiku.sol";
import "contracts/interfaces/IPiku.sol";
import "contracts/interfaces/IERC20Events.sol";
import "contracts/interfaces/ISingleAdminAccessControl.sol";

contract StakedPikuACL is Test, IERC20Events {
  PIKU public pikuToken;
  StakedPiku public stakedPiku;
  SigUtils public sigUtilsPiku;
  SigUtils public sigUtilsStakedPiku;

  address public owner;
  address public rewarder;
  address public alice;
  address public newOwner;
  address public greg;

  bytes32 public DEFAULT_ADMIN_ROLE;
  bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
  bytes32 public constant FULL_RESTRICTED_STAKER_ROLE = keccak256("FULL_RESTRICTED_STAKER_ROLE");

  event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
  event Withdraw(
    address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
  );
  event RewardsReceived(uint256 indexed amount, uint256 newVestingPikuAmount);

  function setUp() public virtual {
    pikuToken = new PIKU(address(this));

    alice = vm.addr(0xB44DE);
    newOwner = vm.addr(0x1DE);
    greg = vm.addr(0x6ED);
    owner = vm.addr(0xA11CE);
    rewarder = vm.addr(0x1DEA);
    vm.label(alice, "alice");
    vm.label(newOwner, "newOwner");
    vm.label(greg, "greg");
    vm.label(owner, "owner");
    vm.label(rewarder, "rewarder");

    vm.prank(owner);
    stakedPiku = new StakedPiku(IPiku(address(pikuToken)), rewarder, owner);

    DEFAULT_ADMIN_ROLE = stakedPiku.DEFAULT_ADMIN_ROLE();

    sigUtilsPiku = new SigUtils(pikuToken.DOMAIN_SEPARATOR());
    sigUtilsStakedPiku = new SigUtils(stakedPiku.DOMAIN_SEPARATOR());
  }

  function testCorrectSetup() public {
    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
  }

  function testCancelTransferAdmin() public {
    vm.startPrank(owner);
    stakedPiku.transferAdmin(newOwner);
    stakedPiku.transferAdmin(address(0));
    vm.stopPrank();
    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
    assertFalse(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, address(0)));
    assertFalse(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
  }

  function test_admin_cannot_transfer_self() public {
    vm.startPrank(owner);
    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    stakedPiku.transferAdmin(owner);
    vm.stopPrank();
    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
  }

  function testAdminCanCancelTransfer() public {
    vm.startPrank(owner);
    stakedPiku.transferAdmin(newOwner);
    stakedPiku.transferAdmin(address(0));
    vm.stopPrank();

    vm.prank(newOwner);
    vm.expectRevert(ISingleAdminAccessControl.NotPendingAdmin.selector);
    stakedPiku.acceptAdmin();

    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
    assertFalse(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, address(0)));
    assertFalse(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
  }

  function testOwnershipCannotBeRenounced() public {
    vm.startPrank(owner);
    vm.expectRevert(IStakedPiku.OperationNotAllowed.selector);
    stakedPiku.renounceRole(DEFAULT_ADMIN_ROLE, owner);

    vm.expectRevert(ISingleAdminAccessControl.InvalidAdminChange.selector);
    stakedPiku.revokeRole(DEFAULT_ADMIN_ROLE, owner);
    vm.stopPrank();
    assertEq(stakedPiku.owner(), owner);
    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
  }

  function testOwnershipTransferRequiresTwoSteps() public {
    vm.prank(owner);
    stakedPiku.transferAdmin(newOwner);
    assertEq(stakedPiku.owner(), owner);
    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
    assertNotEq(stakedPiku.owner(), newOwner);
    assertFalse(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
  }

  function testCanTransferOwnership() public {
    vm.prank(owner);
    stakedPiku.transferAdmin(newOwner);
    vm.prank(newOwner);
    stakedPiku.acceptAdmin();
    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
    assertFalse(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
  }

  function testNewOwnerCanPerformOwnerActions() public {
    vm.prank(owner);
    stakedPiku.transferAdmin(newOwner);
    vm.startPrank(newOwner);
    stakedPiku.acceptAdmin();
    stakedPiku.grantRole(BLACKLIST_MANAGER_ROLE, newOwner);
    stakedPiku.addToBlacklist(alice, true);
    vm.stopPrank();
    assertTrue(stakedPiku.hasRole(FULL_RESTRICTED_STAKER_ROLE, alice));
  }

  function testOldOwnerCantPerformOwnerActions() public {
    vm.prank(owner);
    stakedPiku.transferAdmin(newOwner);
    vm.prank(newOwner);
    stakedPiku.acceptAdmin();
    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
    assertFalse(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    stakedPiku.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertFalse(stakedPiku.hasRole(BLACKLIST_MANAGER_ROLE, alice));
  }

  function testOldOwnerCantTransferOwnership() public {
    vm.prank(owner);
    stakedPiku.transferAdmin(newOwner);
    vm.prank(newOwner);
    stakedPiku.acceptAdmin();
    assertTrue(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, newOwner));
    assertFalse(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, owner));
    vm.prank(owner);
    vm.expectRevert(
      "AccessControl: account 0xe05fcc23807536bee418f142d19fa0d21bb0cff7 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    stakedPiku.transferAdmin(alice);
    assertFalse(stakedPiku.hasRole(DEFAULT_ADMIN_ROLE, alice));
  }

  function testNonAdminCantRenounceRoles() public {
    vm.prank(owner);
    stakedPiku.grantRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedPiku.hasRole(BLACKLIST_MANAGER_ROLE, alice));

    vm.prank(alice);
    vm.expectRevert(IStakedPiku.OperationNotAllowed.selector);
    stakedPiku.renounceRole(BLACKLIST_MANAGER_ROLE, alice);
    assertTrue(stakedPiku.hasRole(BLACKLIST_MANAGER_ROLE, alice));
  }
}

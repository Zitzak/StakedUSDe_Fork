// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";
import {SigUtils} from "forge-std/SigUtils.sol";

import "contracts/token/PIKU.sol";
import "contracts/stakedPiku/StakedPiku.sol";
import "contracts/interfaces/IPiku.sol";
import "contracts/interfaces/IERC20Events.sol";

contract StakedPikuTest is Test, IERC20Events {
  PIKU public pikuToken;
  StakedPiku public stakedPiku;
  SigUtils public sigUtilsPiku;
  SigUtils public sigUtilsStakedPiku;

  address public owner;
  address public rewarder;
  address public alice;
  address public bob;
  address public greg;

  bytes32 REWARDER_ROLE = keccak256("REWARDER_ROLE");

  event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
  event Withdraw(
    address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
  );
  event RewardsReceived(uint256 indexed amount, uint256 newVestingPikuAmount);

  function setUp() public virtual {
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

    vm.prank(owner);
    stakedPiku = new StakedPiku(IPiku(address(pikuToken)), rewarder, owner);

    sigUtilsPiku = new SigUtils(pikuToken.DOMAIN_SEPARATOR());
    sigUtilsStakedPiku = new SigUtils(stakedPiku.DOMAIN_SEPARATOR());

    pikuToken.setMinter(address(this));
  }

  function _mintApproveDeposit(address staker, uint256 amount) internal {
    pikuToken.mint(staker, amount);

    vm.startPrank(staker);
    pikuToken.approve(address(stakedPiku), amount);

    vm.expectEmit(true, true, true, false);
    emit Deposit(staker, staker, amount, amount);

    stakedPiku.deposit(amount, staker);
    vm.stopPrank();
  }

  function _redeem(address staker, uint256 amount) internal {
    vm.startPrank(staker);

    vm.expectEmit(true, true, true, false);
    emit Withdraw(staker, staker, staker, amount, amount);

    stakedPiku.redeem(amount, staker, staker);
    vm.stopPrank();
  }

  function _transferRewards(uint256 amount, uint256 expectedNewVestingAmount) internal {
    pikuToken.mint(address(rewarder), amount);
    vm.startPrank(rewarder);

    pikuToken.approve(address(stakedPiku), amount);

    vm.expectEmit(true, false, false, true);
    emit Transfer(rewarder, address(stakedPiku), amount);
    vm.expectEmit(true, false, false, false);
    emit RewardsReceived(amount, expectedNewVestingAmount);

    stakedPiku.transferInRewards(amount);

    assertApproxEqAbs(stakedPiku.getUnvestedAmount(), expectedNewVestingAmount, 1);
    vm.stopPrank();
  }

  function _assertVestedAmountIs(uint256 amount) internal {
    assertApproxEqAbs(stakedPiku.totalAssets(), amount, 2);
  }

  function testInitialStake() public {
    uint256 amount = 100 ether;
    _mintApproveDeposit(alice, amount);

    assertEq(pikuToken.balanceOf(alice), 0);
    assertEq(pikuToken.balanceOf(address(stakedPiku)), amount);
    assertEq(stakedPiku.balanceOf(alice), amount);
  }

  function testInitialStakeBelowMin() public {
    uint256 amount = 0.99 ether;
    pikuToken.mint(alice, amount);
    vm.startPrank(alice);
    pikuToken.approve(address(stakedPiku), amount);
    vm.expectRevert(IStakedPiku.MinSharesViolation.selector);
    stakedPiku.deposit(amount, alice);

    assertEq(pikuToken.balanceOf(alice), amount);
    assertEq(pikuToken.balanceOf(address(stakedPiku)), 0);
    assertEq(stakedPiku.balanceOf(alice), 0);
  }

  function testCantWithdrawBelowMinShares() public {
    _mintApproveDeposit(alice, 1 ether);

    vm.startPrank(alice);
    pikuToken.approve(address(stakedPiku), 0.01 ether);
    vm.expectRevert(IStakedPiku.MinSharesViolation.selector);
    stakedPiku.redeem(0.5 ether, alice, alice);
  }

  function testCannotStakeWithoutApproval() public {
    uint256 amount = 100 ether;
    pikuToken.mint(alice, amount);

    vm.startPrank(alice);
    vm.expectRevert("ERC20: insufficient allowance");
    stakedPiku.deposit(amount, alice);
    vm.stopPrank();

    assertEq(pikuToken.balanceOf(alice), amount);
    assertEq(pikuToken.balanceOf(address(stakedPiku)), 0);
    assertEq(stakedPiku.balanceOf(alice), 0);
  }

  function testStakeUnstake() public {
    uint256 amount = 100 ether;
    _mintApproveDeposit(alice, amount);

    assertEq(pikuToken.balanceOf(alice), 0);
    assertEq(pikuToken.balanceOf(address(stakedPiku)), amount);
    assertEq(stakedPiku.balanceOf(alice), amount);

    _redeem(alice, amount);

    assertEq(pikuToken.balanceOf(alice), amount);
    assertEq(pikuToken.balanceOf(address(stakedPiku)), 0);
    assertEq(stakedPiku.balanceOf(alice), 0);
  }

  function testOnlyRewarderCanReward() public {
    uint256 amount = 100 ether;
    uint256 rewardAmount = 0.5 ether;
    _mintApproveDeposit(alice, amount);

    pikuToken.mint(bob, rewardAmount);
    vm.startPrank(bob);

    vm.expectRevert(
      "AccessControl: account 0x72c7a47c5d01bddf9067eabb345f5daabdead13f is missing role 0xbeec13769b5f410b0584f69811bfd923818456d5edcf426b0e31cf90eed7a3f6"
    );
    stakedPiku.transferInRewards(rewardAmount);
    vm.stopPrank();
    assertEq(pikuToken.balanceOf(alice), 0);
    assertEq(pikuToken.balanceOf(address(stakedPiku)), amount);
    assertEq(stakedPiku.balanceOf(alice), amount);
    _assertVestedAmountIs(amount);
    assertEq(pikuToken.balanceOf(bob), rewardAmount);
  }

  function testStakingAndUnstakingBeforeAfterReward() public {
    uint256 amount = 100 ether;
    uint256 rewardAmount = 100 ether;
    _mintApproveDeposit(alice, amount);
    _transferRewards(rewardAmount, rewardAmount);
    _redeem(alice, amount);
    assertEq(pikuToken.balanceOf(alice), amount);
    assertEq(stakedPiku.totalSupply(), 0);
  }

  function testFuzzNoJumpInVestedBalance(uint256 amount) public {
    vm.assume(amount > 0 && amount < 1e60);
    _transferRewards(amount, amount);
    vm.warp(block.timestamp + 4 hours);
    _assertVestedAmountIs(amount / 2);
    assertEq(pikuToken.balanceOf(address(stakedPiku)), amount);
  }

  function testOwnerCannotRescuePiku() public {
    uint256 amount = 100 ether;
    _mintApproveDeposit(alice, amount);
    bytes4 selector = bytes4(keccak256("InvalidToken()"));
    vm.startPrank(owner);
    vm.expectRevert(abi.encodeWithSelector(selector));
    stakedPiku.rescueTokens(address(pikuToken), amount, owner);
  }

  function testOwnerCanRescuestPiku() public {
    uint256 amount = 100 ether;
    _mintApproveDeposit(alice, amount);
    vm.prank(alice);
    stakedPiku.transfer(address(stakedPiku), amount);
    assertEq(stakedPiku.balanceOf(owner), 0);
    vm.startPrank(owner);
    stakedPiku.rescueTokens(address(stakedPiku), amount, owner);
    assertEq(stakedPiku.balanceOf(owner), amount);
  }

  function testOwnerCanChangeRewarder() public {
    assertTrue(stakedPiku.hasRole(REWARDER_ROLE, address(rewarder)));
    address newRewarder = address(0x123);
    vm.startPrank(owner);
    stakedPiku.revokeRole(REWARDER_ROLE, rewarder);
    stakedPiku.grantRole(REWARDER_ROLE, newRewarder);
    assertTrue(!stakedPiku.hasRole(REWARDER_ROLE, address(rewarder)));
    assertTrue(stakedPiku.hasRole(REWARDER_ROLE, newRewarder));
    vm.stopPrank();

    pikuToken.mint(rewarder, 1 ether);
    pikuToken.mint(newRewarder, 1 ether);

    vm.startPrank(rewarder);
    pikuToken.approve(address(stakedPiku), 1 ether);
    vm.expectRevert(
      "AccessControl: account 0x5c664540bc6bb6b22e9d1d3d630c73c02edd94b7 is missing role 0xbeec13769b5f410b0584f69811bfd923818456d5edcf426b0e31cf90eed7a3f6"
    );
    stakedPiku.transferInRewards(1 ether);
    vm.stopPrank();

    vm.startPrank(newRewarder);
    pikuToken.approve(address(stakedPiku), 1 ether);
    stakedPiku.transferInRewards(1 ether);
    vm.stopPrank();

    assertEq(pikuToken.balanceOf(address(stakedPiku)), 1 ether);
    assertEq(pikuToken.balanceOf(rewarder), 1 ether);
    assertEq(pikuToken.balanceOf(newRewarder), 0);
  }

  function testPikuValuePerStPiku() public {
    _mintApproveDeposit(alice, 100 ether);
    _transferRewards(100 ether, 100 ether);
    vm.warp(block.timestamp + 4 hours);
    _assertVestedAmountIs(150 ether);
    assertEq(stakedPiku.convertToAssets(1 ether), 1.5 ether - 1);
    assertEq(stakedPiku.totalSupply(), 100 ether);
    // rounding
    _mintApproveDeposit(bob, 75 ether);
    _assertVestedAmountIs(225 ether);
    assertEq(stakedPiku.balanceOf(alice), 100 ether);
    assertEq(stakedPiku.balanceOf(bob), 50 ether);
    assertEq(stakedPiku.convertToAssets(1 ether), 1.5 ether - 1);

    vm.warp(block.timestamp + 4 hours);

    uint256 vestedAmount = 275 ether;
    _assertVestedAmountIs(vestedAmount);

    assertApproxEqAbs(stakedPiku.convertToAssets(1 ether), (vestedAmount * 1 ether) / 150 ether, 1);

    // rounding
    _redeem(bob, stakedPiku.balanceOf(bob));

    _redeem(alice, 100 ether);

    assertEq(stakedPiku.balanceOf(alice), 0);
    assertEq(stakedPiku.balanceOf(bob), 0);
    assertEq(stakedPiku.totalSupply(), 0);

    assertApproxEqAbs(pikuToken.balanceOf(alice), (vestedAmount * 2) / 3, 2);

    assertApproxEqAbs(pikuToken.balanceOf(bob), vestedAmount / 3, 2);

    assertApproxEqAbs(pikuToken.balanceOf(address(stakedPiku)), 0, 1);
  }

  function testFairStakeAndUnstakePrices() public {
    uint256 aliceAmount = 100 ether;
    uint256 bobAmount = 1000 ether;
    uint256 rewardAmount = 200 ether;
    _mintApproveDeposit(alice, aliceAmount);
    _transferRewards(rewardAmount, rewardAmount);
    vm.warp(block.timestamp + 4 hours);
    _mintApproveDeposit(bob, bobAmount);
    vm.warp(block.timestamp + 4 hours);
    _redeem(alice, aliceAmount);
    _assertVestedAmountIs(bobAmount + (rewardAmount * 5) / 12);
  }

  function testFuzzFairStakeAndUnstakePrices(
    uint256 amount1,
    uint256 amount2,
    uint256 amount3,
    uint256 rewardAmount,
    uint256 waitSeconds
  ) public {
    amount1 = bound(amount1, 100 ether, 1e32);
    amount2 = bound(amount2, 1, 1e32);
    amount3 = bound(amount3, 1, 1e32);
    rewardAmount = bound(rewardAmount, 1, 1e32);
    waitSeconds = bound(waitSeconds, 0, 9 hours);

    uint256 totalContributions = amount1;

    // Deposit tokens from alice into the vault
    _mintApproveDeposit(alice, amount1);

    // Add assets to the vault through the rewarding mechanism, vesting them into the vault instead
    // of directly adding them.
    _transferRewards(rewardAmount, rewardAmount);

    vm.warp(block.timestamp + waitSeconds);

    uint256 vestedAmount;

    // Calculate the vested amount based on the wait time.
    if (waitSeconds > 8 hours) {
      // If the wait time is greater than 8 hours, the vested amount is the sum of the initial
      // contribution and the reward amount.
      vestedAmount = amount1 + rewardAmount;
    } else {
      // If the wait time is less than 8 hours, the vested amount is the sum of the initial
      // contribution and the reward amount minus the reward amount multiplied by the ratio of the
      // wait time to 8 hours.
      vestedAmount = amount1 + rewardAmount - (rewardAmount * (8 hours - waitSeconds)) / 8 hours;
    }

    _assertVestedAmountIs(vestedAmount);

    uint256 bobStakedPiku = (amount2 * (amount1 + 1)) / (vestedAmount + 1);
    if (bobStakedPiku > 0) {
      _mintApproveDeposit(bob, amount2);
      totalContributions += amount2;
    }

    vm.warp(block.timestamp + waitSeconds);

    if (waitSeconds > 4 hours) {
      vestedAmount = totalContributions + rewardAmount;
    } else {
      vestedAmount = totalContributions + rewardAmount - ((4 hours - waitSeconds) * rewardAmount) / 4 hours;
    }

    _assertVestedAmountIs(vestedAmount);

    uint256 gregStakedPiku = (amount3 * (stakedPiku.totalSupply() + 1)) / (vestedAmount + 1);
    if (gregStakedPiku > 0) {
      _mintApproveDeposit(greg, amount3);
      totalContributions += amount3;
    }

    vm.warp(block.timestamp + 8 hours);

    vestedAmount = totalContributions + rewardAmount;

    _assertVestedAmountIs(vestedAmount);

    uint256 pikuPerStakedPikuBefore = stakedPiku.convertToAssets(1 ether);
    uint256 bobUnstakeAmount = (stakedPiku.balanceOf(bob) * (vestedAmount + 1)) / (stakedPiku.totalSupply() + 1);
    uint256 gregUnstakeAmount = (stakedPiku.balanceOf(greg) * (vestedAmount + 1)) / (stakedPiku.totalSupply() + 1);

    if (bobUnstakeAmount > 0) _redeem(bob, stakedPiku.balanceOf(bob));
    uint256 pikuPerStakedPikuAfter = stakedPiku.convertToAssets(1 ether);
    if (pikuPerStakedPikuAfter != 0) assertApproxEqAbs(pikuPerStakedPikuAfter, pikuPerStakedPikuBefore, 1 ether);

    if (gregUnstakeAmount > 0) _redeem(greg, stakedPiku.balanceOf(greg));
    pikuPerStakedPikuAfter = stakedPiku.convertToAssets(1 ether);
    if (pikuPerStakedPikuAfter != 0) assertApproxEqAbs(pikuPerStakedPikuAfter, pikuPerStakedPikuBefore, 1 ether);

    _redeem(alice, amount1);

    assertEq(stakedPiku.totalSupply(), 0);
    // assertApproxEqAbs(stakedPiku.totalAssets(), 0, 10 ** 12 + 1); @todo check if can be removed. Initially this was needed to let the tests pass out of the box.
  }

  function testTransferRewardsFailsInsufficientBalance() public {
    pikuToken.mint(address(rewarder), 99);
    vm.startPrank(rewarder);

    pikuToken.approve(address(stakedPiku), 100);

    vm.expectRevert("ERC20: transfer amount exceeds balance");
    stakedPiku.transferInRewards(100);
    vm.stopPrank();
  }

  function testTransferRewardsFailsZeroAmount() public {
    pikuToken.mint(address(rewarder), 100);
    vm.startPrank(rewarder);

    pikuToken.approve(address(stakedPiku), 100);

    vm.expectRevert(IStakedPiku.InvalidAmount.selector);
    stakedPiku.transferInRewards(0);
    vm.stopPrank();
  }

  function testDecimalsIs18() public {
    assertEq(stakedPiku.decimals(), 18);
  }

  function testMintWithSlippageCheck(uint256 amount) public {
    amount = bound(amount, 1 ether, type(uint256).max / 2);
    pikuToken.mint(alice, amount * 2);

    assertEq(stakedPiku.balanceOf(alice), 0);

    vm.startPrank(alice);
    pikuToken.approve(address(stakedPiku), amount);
    vm.expectEmit(true, true, true, true);
    emit Deposit(alice, alice, amount, amount);
    stakedPiku.mint(amount, alice);

    assertEq(stakedPiku.balanceOf(alice), amount);

    pikuToken.approve(address(stakedPiku), amount);
    vm.expectEmit(true, true, true, true);
    emit Deposit(alice, alice, amount, amount);
    stakedPiku.mint(amount, alice);

    assertEq(stakedPiku.balanceOf(alice), amount * 2);
  }

  function testMintToDiffRecipient() public {
    pikuToken.mint(alice, 1 ether);

    vm.startPrank(alice);

    pikuToken.approve(address(stakedPiku), 1 ether);

    stakedPiku.deposit(1 ether, bob);

    assertEq(stakedPiku.balanceOf(alice), 0);
    assertEq(stakedPiku.balanceOf(bob), 1 ether);
  }

  function testCannotTransferRewardsWhileVesting() public {
    _transferRewards(100 ether, 100 ether);
    vm.warp(block.timestamp + 4 hours);
    _assertVestedAmountIs(50 ether);
    vm.prank(rewarder);
    vm.expectRevert(IStakedPiku.StillVesting.selector);
    stakedPiku.transferInRewards(100 ether);
    _assertVestedAmountIs(50 ether);
    assertEq(stakedPiku.vestingAmount(), 100 ether);
  }

  function testCanTransferRewardsAfterVesting() public {
    _transferRewards(100 ether, 100 ether);
    vm.warp(block.timestamp + 8 hours);
    _assertVestedAmountIs(100 ether);
    _transferRewards(100 ether, 100 ether);
    vm.warp(block.timestamp + 8 hours);
    _assertVestedAmountIs(200 ether);
  }

  function testDonationAttack() public {
    uint256 initialStake = 1 ether;
    uint256 donationAmount = 10_000_000_000 ether;
    uint256 bobStake = 100 ether;
    _mintApproveDeposit(alice, initialStake);
    assertEq(stakedPiku.totalSupply(), initialStake);
    pikuToken.mint(alice, donationAmount);
    vm.prank(alice);
    pikuToken.transfer(address(stakedPiku), donationAmount);
    assertEq(stakedPiku.totalSupply(), initialStake);
    assertEq(pikuToken.balanceOf(address(stakedPiku)), initialStake + donationAmount);
    _mintApproveDeposit(bob, bobStake);
    uint256 bobStPikuBal = stakedPiku.balanceOf(bob);
    uint256 bobStPikuExpectedBal = (bobStake * initialStake) / (initialStake + donationAmount);
    assertApproxEqAbs(bobStPikuBal, bobStPikuExpectedBal, 1e9);
    assertTrue(bobStPikuBal > 0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

import {console} from "forge-std/console.sol";
import "forge-std/Test.sol";

import "contracts/token/USDe.sol";
import "test/foundry/stakedPiku/mocks/StakedUSDeMock_Exposed.sol";


// This contract has duplicate tests for ERC20MultiVotes.t.sol. However the contract tested is
// the StakedUSDe contract, which has been adapted to inherit the ERC20MultiVotes contract.
contract StakedUSDeVotingTest is Test {

    StakedUSDeMock_Exposed stakedPiku;
    USDe pikuToken;
    
    address constant delegate1 = address(0xDEAD);
    address constant delegate2 = address(0xBEEF);
    // Min shares taken from the contract
    uint224 internal constant MIN_SHARES = 1 ether;


    function setUp() public {
        // Init test token and TEST contract as minter
        pikuToken = new USDe(address(this));
        pikuToken.setMinter(address(this));

        stakedPiku = new StakedUSDeMock_Exposed(pikuToken, address(this), address(this));
    }

    /*///////////////////////////////////////////////////////////////
                        TEST USER DELEGATION OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice test delegating different delegatees 8 times by multiple users and amounts
    function testDelegate(address[8] memory from, address[8] memory delegates, uint224[8] memory amounts) public {
        stakedPiku.setMaxDelegates(8);

        for (uint256 i = 0; i < 8; i++) {
            vm.assume(from[i] != address(0) && from[i] != address(stakedPiku));
            vm.assume(delegates[i] != address(0) && delegates[i] != address(stakedPiku));
            // Bound the test to reasonable values for 18-decimal tokens
            amounts[i] = uint224(bound(amounts[i], MIN_SHARES, 10_000_000e18));

            // mint PIKU to user
            pikuToken.mint(from[i], amounts[i]);
            // Approve and deposit PIKU to get sPIKU
            vm.startPrank(from[i]);
            pikuToken.approve(address(stakedPiku), amounts[i]);
            stakedPiku.deposit(amounts[i], from[i]);
            vm.stopPrank();

            uint256 userDelegatedBefore = stakedPiku.userDelegatedVotes(from[i]);
            uint256 delegateVotesBefore = stakedPiku.delegatesVotesCount(from[i], delegates[i]);
            uint256 votesBefore = stakedPiku.getVotes(delegates[i]);
            console.log("votesBefore", votesBefore);
            console.log("amounts[i]", amounts[i]);

            vm.prank(from[i]);
            stakedPiku.incrementDelegation(delegates[i], amounts[i]);
            require(stakedPiku.delegatesVotesCount(from[i], delegates[i]) == delegateVotesBefore + amounts[i]);
            require(stakedPiku.userDelegatedVotes(from[i]) == userDelegatedBefore + amounts[i]);
            require(stakedPiku.getVotes(delegates[i]) == votesBefore + amounts[i]);
        }
    }


    /// @notice test undelegate twice, 2 tokens each after delegating by 4.
    function testUndelegate() public {
        // Setup
        // mint PIKU, deposit to get sPIKU, which can be delegateed
        pikuToken.mint(address(this), 100e18);
        pikuToken.approve(address(stakedPiku), 100e18);
        stakedPiku.deposit(100e18, address(this));
        stakedPiku.setMaxDelegates(2);

        stakedPiku.incrementDelegation(delegate1, 4e18);

        stakedPiku.undelegate(delegate1, 2e18);
        require(stakedPiku.delegatesVotesCount(address(this), delegate1) == 2e18);
        require(stakedPiku.userDelegatedVotes(address(this)) == 2e18);
        require(stakedPiku.getVotes(delegate1) == 2e18);
        require(stakedPiku.freeVotes(address(this)) == 98e18);

        stakedPiku.undelegate(delegate1, 2e18);
        require(stakedPiku.delegatesVotesCount(address(this), delegate1) == 0);
        require(stakedPiku.userDelegatedVotes(address(this)) == 0);
        require(stakedPiku.getVotes(delegate1) == 0);
        require(stakedPiku.freeVotes(address(this)) == 100e18);
    }

    function testBackwardCompatibleDelegate(
        address oldDelegatee,
        uint112 beforeDelegateAmount,
        address newDelegatee,
        uint112 mintAmount
    ) public {
        mintAmount = uint112(bound(mintAmount, MIN_SHARES, 10_000_000e18));

        beforeDelegateAmount %= mintAmount;
        beforeDelegateAmount++;

        pikuToken.mint(address(this), mintAmount);
        pikuToken.approve(address(stakedPiku), mintAmount);
        stakedPiku.deposit(mintAmount, address(this));
        stakedPiku.setMaxDelegates(2);

        if (oldDelegatee == address(0)) {
            vm.expectRevert(abi.encodeWithSignature("DelegationError()"));
        }

        stakedPiku.incrementDelegation(oldDelegatee, beforeDelegateAmount);

        stakedPiku.delegate(newDelegatee);

        uint256 expected = newDelegatee == address(0) ? 0 : mintAmount;
        uint256 expectedFree = newDelegatee == address(0) ? mintAmount : 0;

        require(oldDelegatee == newDelegatee || stakedPiku.delegatesVotesCount(address(this), oldDelegatee) == 0);
        require(stakedPiku.delegatesVotesCount(address(this), newDelegatee) == expected);
        require(stakedPiku.userDelegatedVotes(address(this)) == expected);
        require(stakedPiku.getVotes(newDelegatee) == expected);
        require(stakedPiku.freeVotes(address(this)) == expectedFree);
    }

    function testBackwardCompatibleDelegateBySig(
        uint128 delegatorPk,
        address oldDelegatee,
        uint112 beforeDelegateAmount,
        address newDelegatee,
        uint112 mintAmount
    ) public {
        if (delegatorPk == 0) delegatorPk++;
        address owner = vm.addr(delegatorPk);

        mintAmount = uint112(bound(mintAmount, MIN_SHARES, 10_000_000e18));

        beforeDelegateAmount %= mintAmount;
        beforeDelegateAmount++;

        pikuToken.mint(owner, mintAmount);
        vm.startPrank(owner);
        pikuToken.approve(address(stakedPiku), mintAmount);
        stakedPiku.deposit(mintAmount, owner);
        vm.stopPrank();

        stakedPiku.setMaxDelegates(2);

        if (oldDelegatee == address(0)) {
            vm.expectRevert(abi.encodeWithSignature("DelegationError()"));
        }

        vm.prank(owner);
        stakedPiku.incrementDelegation(oldDelegatee, beforeDelegateAmount);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            delegatorPk,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    stakedPiku.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(stakedPiku.DELEGATION_TYPEHASH(), newDelegatee, 0, block.timestamp))
                )
            )
        );

        uint256 expected = newDelegatee == address(0) ? 0 : mintAmount;
        uint256 expectedFree = newDelegatee == address(0) ? mintAmount : 0;

        stakedPiku.delegateBySig(newDelegatee, 0, block.timestamp, v, r, s);
        require(oldDelegatee == newDelegatee || stakedPiku.delegatesVotesCount(owner, oldDelegatee) == 0);
        require(stakedPiku.delegatesVotesCount(owner, newDelegatee) == expected);
        require(stakedPiku.userDelegatedVotes(owner) == expected);
        require(stakedPiku.getVotes(newDelegatee) == expected);
        require(stakedPiku.freeVotes(owner) == expectedFree);
    }

    struct DelegateAmountTestParams {
        uint128 delegatorPk;
        address oldDelegatee;
        uint112 beforeDelegateAmount;
        address newDelegatee;
        uint112 mintAmount;
        uint112 delegateAmountToIncrease;
    }

    function testBackwardCompatibleDelegateAmountBySig(DelegateAmountTestParams memory params) public {
        if (params.delegatorPk == 0) params.delegatorPk++;
        address owner = vm.addr(params.delegatorPk);

        params.mintAmount = uint112(bound(params.mintAmount, MIN_SHARES, 10_000_000e18));

        params.beforeDelegateAmount %= params.mintAmount;
        params.beforeDelegateAmount++;

        pikuToken.mint(owner, params.mintAmount);
        vm.startPrank(owner);
        pikuToken.approve(address(stakedPiku), params.mintAmount);
        stakedPiku.deposit(params.mintAmount, owner);
        vm.stopPrank();

        stakedPiku.setMaxDelegates(2);

        bool oldDelegateIsZeroAddress = params.oldDelegatee == address(0);
        uint256 expectedBefore = params.beforeDelegateAmount;

        if (oldDelegateIsZeroAddress) {
            expectedBefore = 0;
            vm.expectRevert(abi.encodeWithSignature("DelegationError()"));
        }

        vm.prank(owner);
        stakedPiku.incrementDelegation(params.oldDelegatee, params.beforeDelegateAmount);

        if (params.mintAmount == params.beforeDelegateAmount) params.delegateAmountToIncrease = 0;
        else params.delegateAmountToIncrease %= (params.mintAmount - params.beforeDelegateAmount);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            params.delegatorPk,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    stakedPiku.DOMAIN_SEPARATOR(),
                    keccak256(
                        abi.encode(
                            stakedPiku.DELEGATION_AMOUNT_TYPEHASH(),
                            params.newDelegatee,
                            params.delegateAmountToIncrease,
                            0,
                            block.timestamp
                        )
                    )
                )
            )
        );

        bool newDelegateIsZeroAddress = params.newDelegatee == address(0);
        bool amountToIncreaseIsZero = params.delegateAmountToIncrease == 0;

        uint256 expected = params.delegateAmountToIncrease;

        if (newDelegateIsZeroAddress || amountToIncreaseIsZero) {
            expected = 0;
            vm.expectRevert(abi.encodeWithSignature("DelegationError()"));
        }

        uint256 expectedUsed = expected + expectedBefore;
        uint256 expectedFree = params.mintAmount - expectedUsed;

        stakedPiku.delegateAmountBySig(params.newDelegatee, params.delegateAmountToIncrease, 0, block.timestamp, v, r, s);
        if (params.oldDelegatee == params.newDelegatee) {
            assertEq(stakedPiku.delegatesVotesCount(owner, params.newDelegatee), expectedUsed);
            assertEq(stakedPiku.getVotes(params.newDelegatee), expectedUsed);
        } else {
            assertEq(stakedPiku.delegatesVotesCount(owner, params.oldDelegatee), expectedBefore);
            assertEq(stakedPiku.delegatesVotesCount(owner, params.newDelegatee), expected);
            assertEq(stakedPiku.getVotes(params.newDelegatee), expected);
        }
        assertEq(stakedPiku.userDelegatedVotes(owner), expectedUsed);

        assertEq(stakedPiku.freeVotes(owner), expectedFree);
    }

    /*///////////////////////////////////////////////////////////////
                            TEST PAST VOTES
    //////////////////////////////////////////////////////////////*/

    function testPastVotes() public {
        pikuToken.mint(address(this), 100e18);
        pikuToken.approve(address(stakedPiku), 100e18);
        stakedPiku.deposit(100e18, address(this));
        stakedPiku.setMaxDelegates(2);

        stakedPiku.incrementDelegation(delegate1, 4e18);

        uint256 block1 = block.number;
        assertEq(stakedPiku.numCheckpoints(delegate1), 1);
        StakedUSDeMock_Exposed.Checkpoint memory checkpoint1 = stakedPiku.checkpoints(delegate1, 0);
        assertEq(checkpoint1.fromBlock, block1);
        assertEq(checkpoint1.votes, 4e18);

        // Same block increase voting power
        stakedPiku.incrementDelegation(delegate1, 4e18);

        assertEq(stakedPiku.numCheckpoints(delegate1), 1);
        checkpoint1 = stakedPiku.checkpoints(delegate1, 0);
        assertEq(checkpoint1.fromBlock, block1);
        assertEq(checkpoint1.votes, 8e18);

        vm.roll(2);
        uint256 block2 = block.number;
        assertEq(block2, block1 + 1);

        // Next block decrease voting power
        stakedPiku.undelegate(delegate1, 2e18);

        assertEq(stakedPiku.numCheckpoints(delegate1), 2); // new checkpint

        // checkpoint 1 stays same
        checkpoint1 = stakedPiku.checkpoints(delegate1, 0);
        assertEq(checkpoint1.fromBlock, block1);
        assertEq(checkpoint1.votes, 8e18);

        // new checkpoint 2
        StakedUSDeMock_Exposed.Checkpoint memory checkpoint2 = stakedPiku.checkpoints(delegate1, 1);
        assertEq(checkpoint2.fromBlock, block2);
        assertEq(checkpoint2.votes, 6e18);

        vm.roll(10);
        uint256 block3 = block.number;
        assertEq(block3, block2 + 8);

        // 10 blocks later increase voting power
        stakedPiku.incrementDelegation(delegate1, 4e18);

        assertEq(stakedPiku.numCheckpoints(delegate1), 3); // new checkpint

        // checkpoint 1 stays same
        checkpoint1 = stakedPiku.checkpoints(delegate1, 0);
        assertEq(checkpoint1.fromBlock, block1);
        assertEq(checkpoint1.votes, 8e18);

        // checkpoint 2 stays same
        checkpoint2 = stakedPiku.checkpoints(delegate1, 1);
        assertEq(checkpoint2.fromBlock, block2);
        assertEq(checkpoint2.votes, 6e18);

        // new checkpoint 3
        StakedUSDeMock_Exposed.Checkpoint memory checkpoint3 = stakedPiku.checkpoints(delegate1, 2);
        assertEq(checkpoint3.fromBlock, block3);
        assertEq(checkpoint3.votes, 10e18);

        // finally, test getPriorVotes between checkpoints
        assertEq(stakedPiku.getPriorVotes(delegate1, block1), 8e18);
        assertEq(stakedPiku.getPriorVotes(delegate1, block2), 6e18);
        assertEq(stakedPiku.getPriorVotes(delegate1, block2 + 4), 6e18);
        assertEq(stakedPiku.getPriorVotes(delegate1, block3 - 1), 6e18);

        vm.expectRevert(abi.encodeWithSignature("BlockError()"));
        stakedPiku.getPriorVotes(delegate1, block3); // revert same block

        vm.roll(11);
        assertEq(stakedPiku.getPriorVotes(delegate1, block3), 10e18);
    }

    /*///////////////////////////////////////////////////////////////
                            TEST ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function testDecrementUntilFreeWhenFree() public {
        pikuToken.mint(address(this), 100e18);
        pikuToken.approve(address(stakedPiku), 100e18);
        stakedPiku.deposit(100e18, address(this));

        stakedPiku.setMaxDelegates(2);

        stakedPiku.incrementDelegation(delegate1, 10e18);
        stakedPiku.incrementDelegation(delegate2, 20e18);
        require(stakedPiku.freeVotes(address(this)) == 70e18);

        stakedPiku.exposed_burn(address(this), 50e18);
        require(stakedPiku.freeVotes(address(this)) == 20e18);

        require(stakedPiku.delegatesVotesCount(address(this), delegate1) == 10e18);
        require(stakedPiku.userDelegatedVotes(address(this)) == 30e18);
        require(stakedPiku.getVotes(delegate1) == 10e18);
        require(stakedPiku.delegatesVotesCount(address(this), delegate2) == 20e18);
        require(stakedPiku.getVotes(delegate2) == 20e18);
    }

    function testDecrementUntilFreeSingle() public {
        pikuToken.mint(address(this), 100e18);
        pikuToken.approve(address(stakedPiku), 100e18);
        stakedPiku.deposit(100e18, address(this));

        stakedPiku.setMaxDelegates(2);

        stakedPiku.incrementDelegation(delegate1, 10e18);
        stakedPiku.incrementDelegation(delegate2, 20e18);
        require(stakedPiku.freeVotes(address(this)) == 70e18);

        stakedPiku.transfer(address(1), 80e18);
        require(stakedPiku.freeVotes(address(this)) == 0);

        require(stakedPiku.delegatesVotesCount(address(this), delegate1) == 0);
        require(stakedPiku.userDelegatedVotes(address(this)) == 20e18);
        require(stakedPiku.getVotes(delegate1) == 0);
        require(stakedPiku.delegatesVotesCount(address(this), delegate2) == 20e18);
        require(stakedPiku.getVotes(delegate2) == 20e18);
    }

    function testDecrementUntilFreeDouble() public {
        pikuToken.mint(address(this), 100e18);
        pikuToken.approve(address(stakedPiku), 100e18);
        stakedPiku.deposit(100e18, address(this));

        stakedPiku.setMaxDelegates(2);

        stakedPiku.incrementDelegation(delegate1, 10e18);
        stakedPiku.incrementDelegation(delegate2, 20e18);
        require(stakedPiku.freeVotes(address(this)) == 70e18);

        stakedPiku.approve(address(1), 100e18);
        vm.prank(address(1));
        stakedPiku.transferFrom(address(this), address(1), 90e18);

        require(stakedPiku.freeVotes(address(this)) == 10e18);

        require(stakedPiku.delegatesVotesCount(address(this), delegate1) == 0);
        require(stakedPiku.userDelegatedVotes(address(this)) == 0);
        require(stakedPiku.getVotes(delegate1) == 0);
        require(stakedPiku.delegatesVotesCount(address(this), delegate2) == 0);
        require(stakedPiku.getVotes(delegate2) == 0);
    }

}
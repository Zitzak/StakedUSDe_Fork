// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v1;

// Allows anyone to claim a token if they exist in a merkle root.
interface ICumulativeMerkleDrop128 {
    // This event is triggered whenever a call to #setMerkleRoot succeeds.
    event MerkelRootUpdated(bytes16 oldMerkleRoot, bytes16 newMerkleRoot);
    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(address indexed account, uint256 amount);

    error InvalidProof();
    error NothingToClaim();
    error MerkleRootWasUpdated();

    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing cumulative account balances available to claim.
    function merkleRoot() external view returns (bytes16);
    // Sets the merkle root of the merkle tree containing cumulative account balances available to claim.
    function setMerkleRoot(bytes16 merkleRoot_) external;
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(
        bytes16 salt,
        address account,
        uint256 cumulativeAmount,
        bytes16 expectedMerkleRoot,
        bytes calldata merkleProof
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IPikuSiloDefinitions {
  /// @notice Error emitted when the staking vault is not the caller
  error OnlyStakingVault();
}

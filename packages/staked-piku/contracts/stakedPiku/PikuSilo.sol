// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/interfaces/IPikuSiloDefinitions.sol";

/**
 * @title PikuSilo
 * @notice The Silo allows to store PIKU during the stake cooldown process.
 */
contract PikuSilo is IPikuSiloDefinitions {
  using SafeERC20 for IERC20;

  address immutable STAKING_VAULT;
  IERC20 immutable PIKU;

  constructor(address stakingVault, address piku) {
    STAKING_VAULT = stakingVault;
    PIKU = IERC20(piku);
  }

  modifier onlyStakingVault() {
    if (msg.sender != STAKING_VAULT) revert OnlyStakingVault();
    _;
  }

  function withdraw(address to, uint256 amount) external onlyStakingVault {
    PIKU.transfer(to, amount);
  }
}

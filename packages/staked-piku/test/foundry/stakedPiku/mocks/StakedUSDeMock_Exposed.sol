// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import {StakedUSDe} from "contracts/stakedPiku/StakedUSDe.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakedUSDeMock_Exposed is StakedUSDe {

    constructor(IERC20 _asset, address _initialRewarder, address _owner) StakedUSDe(_asset, _initialRewarder, _owner) {}


    function exposed_burn(address account, uint256 amount) public {
        _burn(account, amount);
    }
}
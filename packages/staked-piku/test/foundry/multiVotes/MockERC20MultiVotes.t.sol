// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20MultiVotes, ERC20MultiVotes, ERC20Permit} from "contracts/multiVotes/ERC20MultiVotes.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20MultiVotes is ERC20MultiVotes {
    constructor() ERC20Permit("Token") ERC20("Token", "TKN") {
        // _initializeOwner(_owner);
    }

    function mint(address to, uint256 value) public virtual {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public virtual {
        _burn(from, value);
    }
}
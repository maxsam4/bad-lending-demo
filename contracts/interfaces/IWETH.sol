// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
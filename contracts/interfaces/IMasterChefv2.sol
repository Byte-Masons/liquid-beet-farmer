// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasterChefv2 {
    function harvest(uint256 pid, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function deposit(uint256 pid, uint256 amount, address to) external;
    function lqdrPerBlock() external view returns (uint256);
}
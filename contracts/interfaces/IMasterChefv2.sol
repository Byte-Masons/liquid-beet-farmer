// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMasterChefv2 {
    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function poolLength() external view returns (uint256);

    function lqdrPerBlock() external view returns (uint256);

    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);

    function pendingLqdr(uint256 _pid, address _user) external view returns (uint256);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function massHarvestFromStrategies() external;

    function emergencyWithdraw(uint256 _pid, address _to) external;

    function withdrawAndHarvest(
        uint256 _pid,
        uint256 _amount,
        address _to
    ) external;

    function harvest(uint256 pid, address to) external;

    function harvestFromMasterChef() external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        address to
    ) external;

    function deposit(
        uint256 pid,
        uint256 amount,
        address to
    ) external;
}

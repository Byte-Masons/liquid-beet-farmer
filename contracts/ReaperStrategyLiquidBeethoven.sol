// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './abstract/ReaperBaseStrategyv2.sol';
import './interfaces/IAsset.sol';
import './interfaces/IBasePool.sol';
import './interfaces/IBeetVault.sol';
import './interfaces/ILinearPool.sol';
import './interfaces/IMasterChef.sol';
import './interfaces/IUniswapV2Router.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';

/**
 * @dev Strategy description
 *
 * Expect the amount of staked tokens you have to grow over time while you have assets deposit
 */
contract ReaperStrategyLiquidBeethoven is ReaperBaseStrategyv2 {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // 3rd-party contract addresses
    address public constant BEET_VAULT = address(0x20dd72Ed959b6147912C2e529F0a0C651c33c9ce);
    address public constant MASTER_CHEF = address(0x6e2ad6527901c9664f016466b8DA1357a004db0f);
    address public constant SPOOKY_ROUTER = address(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
    address public constant SPIRIT_ROUTER = address(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52);

    /**
     * @dev Tokens Used:
     * {want} - LP token for the Beethoven-x pool.
     * {WFTM} - Required for charging fees and joining pool.
     * {LQDR} - Reward token for farming in the MasterChef
     * {WFTM_LINEAR_BPT} - Other pool token that's used to join pool via swaps.
     */
    address public constant want = address(0xc0064b291bd3D4ba0E44ccFc81bF8E7f7a579cD2);
    address public constant WFTM = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    address public constant LQDR = address(0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9);
    address public constant WFTM_LINEAR_BPT = address(0xC3BF643799237588b7a6B407B3fc028Dd4e037d2);

    // pools used to swap tokens
    bytes32 public constant WFTM_LINEAR_POOL = 0xc3bf643799237588b7a6b407b3fc028dd4e037d200000000000000000000022d;

    /**
     * @dev Strategy variables
     * {poolId} - ID of MasterChef pool in which to deposit LP tokens
     * {beetsPoolId} - bytes32 ID of the Beethoven-X pool corresponding to {want}
     */
    uint256 public constant poolId = 42;
    bytes32 public constant beetsPoolId = 0xc0064b291bd3d4ba0e44ccfc81bf8e7f7a579cd200000000000000000000042c;

    /**
     * @dev Initializes the strategy. Sets parameters and saves routes.
     * @notice see documentation for each variable above its respective declaration.
     */
    function initialize(
        address _vault,
        address[] memory _feeRemitters,
        address[] memory _strategists
    ) public initializer {
        __ReaperBaseStrategy_init(_vault, _feeRemitters, _strategists);
    }

    /**
     * @dev Function that puts the funds to work.
     *      It gets called whenever someone deposits in the strategy's vault contract.
     */
    function _deposit() internal override {
         uint256 wantBalance = IERC20Upgradeable(want).balanceOf(address(this));

        if (wantBalance != 0) {
            IERC20Upgradeable(want).safeIncreaseAllowance(MASTER_CHEF, wantBalance);
            IMasterChef(MASTER_CHEF).deposit(poolId, wantBalance, address(this));
        }
    }

    /**
     * @dev Withdraws funds and sends them back to the vault.
     */
    function _withdraw(uint256 _amount) internal override {
        uint256 wantBal = IERC20Upgradeable(want).balanceOf(address(this));
        if (wantBal < _amount) {
            IMasterChef(MASTER_CHEF).withdraw(poolId, _amount - wantBal, address(this));
        }

        IERC20Upgradeable(want).safeTransfer(vault, _amount);
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     *      1. Claim {BEETS} and {SD} rewards from MasterChef.
     *      2. Perform swaps and charge fees.
     *      3. Create more {want} by "swapping in" to pool.
     *      4. Deposit.
     */
    function _harvestCore() internal override {
        _claimRewards();
        _swapRewardToWftm();
        _chargeFees();
        _addLiquidity();
        deposit();
    }

    function _claimRewards() internal {
        IMasterChef(MASTER_CHEF).harvest(poolId, address(this));
    }

    /**
     * @dev Swaps {REWARD_TOKEN} farmed to {WFTM}
     */
    function _swapRewardToWftm() internal {
        uint256 lqdrBalance = IERC20Upgradeable(LQDR).balanceOf(address(this));
        address[] memory lqdrToWftmRoute = new address[](2);
        lqdrToWftmRoute[0] = LQDR;
        lqdrToWftmRoute[1] = WFTM;
        IERC20Upgradeable(LQDR).safeIncreaseAllowance(SPIRIT_ROUTER, lqdrBalance);
        IUniswapV2Router(SPIRIT_ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            lqdrBalance,
            0,
            lqdrToWftmRoute,
            address(this),
            block.timestamp + 600
        );
    }

    /**
     * @dev Core harvest function.
     *      Charges fees based on the amount of WFTM gained from reward
     */
    function _chargeFees() internal {
        uint256 wftmFee = (IERC20Upgradeable(WFTM).balanceOf(address(this)) * totalFee) / PERCENT_DIVISOR;
        if (wftmFee != 0) {
            uint256 callFeeAmount = (wftmFee * callFee) / PERCENT_DIVISOR;
            uint256 treasuryFeeAmount = (wftmFee * treasuryFee) / PERCENT_DIVISOR;
            uint256 strategistFeeAmount = (treasuryFeeAmount * strategistFee) / PERCENT_DIVISOR;
            treasuryFeeAmount -= strategistFeeAmount;

            IERC20Upgradeable(WFTM).safeTransfer(msg.sender, callFeeAmount);
            IERC20Upgradeable(WFTM).safeTransfer(treasury, treasuryFeeAmount);
            IERC20Upgradeable(WFTM).safeTransfer(strategistRemitter, strategistFeeAmount);
        }
    }

    /**
     * @dev Core harvest function.
     *      Creates new {want} tokens using {WFTM} balance.
     */
    function _addLiquidity() internal {
        _swap(WFTM, WFTM_LINEAR_BPT, IERC20Upgradeable(WFTM).balanceOf(address(this)), WFTM_LINEAR_POOL, true);
        _swap(WFTM_LINEAR_BPT, want, IERC20Upgradeable(WFTM_LINEAR_BPT).balanceOf(address(this)), beetsPoolId, false);
    }

    /**
     * @dev Core harvest function. Swaps {_amount} of {_from} to {_to} using {_poolId}.
     *      Prior to requesting the swap, allowance is increased iff {_shouldIncreaseAllowance}
     *      is true. This needs to false for the linear pool since they already have max allowance
     *      for {BEET_VAULT}.
     */
    function _swap(
        address _from,
        address _to,
        uint256 _amount,
        bytes32 _poolId,
        bool _shouldIncreaseAllowance
    ) internal {
        if (_from == _to || _amount == 0) {
            return;
        }

        IBeetVault.SingleSwap memory singleSwap;
        singleSwap.poolId = _poolId;
        singleSwap.kind = IBeetVault.SwapKind.GIVEN_IN;
        singleSwap.assetIn = IAsset(_from);
        singleSwap.assetOut = IAsset(_to);
        singleSwap.amount = _amount;
        singleSwap.userData = abi.encode(0);

        IBeetVault.FundManagement memory funds;
        funds.sender = address(this);
        funds.fromInternalBalance = false;
        funds.recipient = payable(address(this));
        funds.toInternalBalance = false;

        if (_shouldIncreaseAllowance) {
            IERC20Upgradeable(_from).safeIncreaseAllowance(BEET_VAULT, _amount);
        }
        IBeetVault(BEET_VAULT).swap(singleSwap, funds, 1, block.timestamp);
    }

    /**
     * @dev Function to calculate the total {want} held by the strat.
     *      It takes into account both the funds in hand, plus the funds in the MasterChef.
     */
    function balanceOf() public view override returns (uint256) {
        (uint256 amount, ) = IMasterChef(MASTER_CHEF).userInfo(poolId, address(this));
        return amount + IERC20Upgradeable(want).balanceOf(address(this));
    }

    /**
     * @dev Returns the approx amount of profit from harvesting.
     *      Profit is denominated in WFTM, and takes fees into account.
     */
    function estimateHarvest() external view override returns (uint256 profit, uint256 callFeeToUser) {
        address[] memory lqdrToWftmRoute = new address[](2);
        lqdrToWftmRoute[0] = LQDR;
        lqdrToWftmRoute[1] = WFTM;
        uint256 pendingLqdr = IMasterChef(MASTER_CHEF).pendingLqdr(poolId, address(this));
        uint256 totalRewards = pendingLqdr + IERC20Upgradeable(LQDR).balanceOf(address(this));

        uint256 wftmFromProfit = IUniswapV2Router(SPIRIT_ROUTER).getAmountsOut(
            totalRewards,
            lqdrToWftmRoute
        )[1];

        uint256 totalWftm = wftmFromProfit + IERC20Upgradeable(WFTM).balanceOf(address(this));
        profit = (totalWftm * totalFee) / PERCENT_DIVISOR;
        callFeeToUser = (profit * callFee) / PERCENT_DIVISOR;
        profit -= callFeeToUser;
    }

    /**
     * Withdraws all funds leaving rewards behind.
     */
    function _reclaimWant() internal override {
        IMasterChef(MASTER_CHEF).emergencyWithdraw(poolId, address(this));
    }
}

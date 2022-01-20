// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './ReaperBaseStrategy.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IComptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /***  Comp claims ****/
    function claimComp(address holder) external;

    function claimComp(address holder, CTokenI[] memory cTokens) external;

    function markets(address ctoken)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function compSpeeds(address ctoken) external view returns (uint256); // will be deprecated
    function compSupplySpeeds(address ctoken) external view returns (uint256);
    function compBorrowSpeeds(address ctoken) external view returns (uint256);

    function oracle() external view returns (address);
}

/**
 * @dev Strategy description
 *
 * Expect the amount of staked tokens you have to grow over time while you have assets deposit
 */
contract ReaperAutoCompoundScStable is ReaperBaseStrategy {
    using SafeERC20 for IERC20;

    /**
     * @dev Tokens Used:
     * {wftm} - Required for liquidity routing when doing swaps.
     * {tokens} - Tokens accepted by the strategy. [frax, dola, mim, tusd, usdc, dai, fUsdt]
     * {scTokens} - scTokens used by the strategy. [scFrax, scDola, scMim, scTusd, scUsdc, scDai, scFUsdt]
     * {rewardToken} - Reward token of the protocol. Scream
     */
    address public constant wftm = address(0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83);
    IERC20[] public tokens = [
        IERC20(address(0xdc301622e621166BD8E82f2cA0A26c13Ad0BE355)),
        IERC20(address(0x3129662808bEC728a27Ab6a6b9AFd3cBacA8A43c)),
        IERC20(address(0x82f0B8B456c1A451378467398982d4834b6829c1)),
        IERC20(address(0x9879aBDea01a879644185341F7aF7d8343556B7a)),
        IERC20(address(0x04068DA6C83AFCFA0e13ba15A6696662335D5B75)),
        IERC20(address(0x8D11eC38a3EB5E956B052f67Da8Bdc9bef8Abf3E)),
        IERC20(address(0x049d68029688eAbF473097a2fC38ef61633A3C7A))
    ];
    address[] public scTokens = [
        address(0x383D965C8D2ac0A9c1F6930ad10943606BcA4cB7),
        address(0x5A3B9Dcdd462f264eC1bD56D618BF4552C2EaF8A),
        address(0x90B7C21Be43855aFD2515675fc307c084427404f),
        address(0x789B5DBd47d7Ca3799f8E9FdcE01bC5E356fcDF1),
        address(0xE45Ac34E528907d0A0239ab5Db507688070B20bf),
        address(0x8D9AED9882b4953a0c9fa920168fa1FDfA0eBE75),
        address(0x02224765BC8D54C21BB51b0951c80315E1c263F9)
    ];
    address public constant rewardToken = address(0xe0654C8e6fd4D733349ac7E09f6f23DA256bF475);
    address public previousStakedToken;
    address public stakedToken;

    /**
     * @dev Third Party Contracts:
     * {uniRouter} - the uniRouter for target DEX
     */
    IUniswapV2Router02 public constant uniRouterSpooky = IUniswapV2Router02(address(0xF491e7B69E4244ad4002BC14e878a34207E38c29));
    IUniswapV2Router02 public constant uniRouterSpirit = IUniswapV2Router02(address(0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52));
    IComptroller public constant screamComptroller = IComptroller(address(0x260E596DAbE3AFc463e75B6CC05d8c46aCAcFB09));

    /**
     * @dev Functional variables
     */
     uint256 public targetLTV = 7500; // total borrow / total supply ratio we are targeting. Scream allows up to 75% for stables

    /**
     * @dev Mapping to get the router need to swap a token
     */
     mapping(address => IUniswapV2Router02 ) public tokenToRouter;

    /**
     * @dev Routes we take to swap tokens using routers.
     * {rewardTokenToWftmRoute} - Route we take to get from {rewardToken} into {wftm}.
     * {rewardTokenToStakedTokenRoute} - Route we take to get from {rewardToken} into {stakedToken}.
     */
    address[] public rewardTokenToWftmRoute = [rewardToken, wftm];
    address[] public previousStakedTokenToWftmRoute = [previousStakedToken, wftm];
    address[] public wftmTokenToStakedToken = [wftm, stakedToken];

    /**
     * @dev Initializes the strategy. Sets parameters, saves routes, and gives allowances.
     * @notice see documentation for each variable above its respective declaration.
     */
    constructor(
        address _vault,
        address[] memory _feeRemitters,
        address[] memory _strategists
    ) ReaperBaseStrategy(_vault, _feeRemitters, _strategists) {
        _giveAllowances();
    }

    /**
     * @dev Function that puts the funds to work.
     * It gets called whenever someone deposits in the strategy's vault contract.
     */
    function deposit() public whenNotPaused {
        //todo  get balance of strat
        //      deposit in protocol
    }

    /**
     * @dev Withdraws funds and sents them back to the vault.
     * It withdraws {stakedToken} from the protocol.
     * The available {stakedToken} minus fees is returned to the vault.
     */
    function withdraw(uint256 _amount) external {
        require(_msgSender() == vault, '!vault');
        //todo  get balance in strat
        //      is balance of strat enough ?
        //      if not, withdraw from protocol
        //      if withdrawn too much, reduce to amount
        //      calculate and deduct withdrawFee
        //      send sh*t to vault
    }

    /**
     * @dev Core function of the strat, in charge of collecting and re-investing rewards.
     * 1. It claims rewards from the protocol.
     * 2. It charges the system fees to simplify the split.
     * 3. It swaps the {rewardToken} token for {stakedToken}
     * 4. Adds more liquidity to the pool if on another block than the rewards' claiming.
     * 5. It deposits the new stakedTokens.
     */
    function _harvestCore() internal override whenNotPaused {
        //todo claim rewards + add strategy-specific logic
        _chargeFees();
        _addLiquidity();
        deposit();
    }

    /**
     * @dev Returns the approx amount of profit from harvesting plus fee that
     *      would be returned to harvest caller.
     */
    function estimateHarvest() external view virtual override returns (uint256 profit, uint256 callFeeToUser) {
        //todo  get reward amount
        //      convert to wftm to get profit
        //      calculate callfee
        //      substract callfee from profit
    }

    /**
     * @dev Takes out fees from the rewards. Set by constructor
     *      callFeeToUser is set as a percentage of the fee,
     *      as is treasuryFeeToVault
     *      strategistFee is based on treasuryFeeToVault
     */
    function _chargeFees() internal {
        //todo  update to fit strategy
        //      get balance of reward or wftm
        //      swap to wftm
        //      calculate callFee, treasuryFee, feeToStrategist
        //      transfer this sh*t (use paymentrouter for strategists)
    }

    /**
     * @dev Swaps {rewardToken} for {stakedToken} using SpookySwap.
     */
    function _addLiquidity() internal {
        //todo update to fit strategy
        //      get balance of reward
        //      swap to staked
    }

    function addTokenAndScToken(address _token, address _scToken) external {
        _onlyStrategistOrOwner();
        //verify that token matches sctoken's underlying
        //if yes, success=true
    }

    function setTargetLtv(uint256 _targetLtv) external {
        _onlyStrategistOrOwner();
        (, uint256 collateralFactorMantissa, ) = compound.markets(address(stakedToken));
    }

    /**
     * @dev Function to calculate the total underlying {token} held by the strat.
     * It takes into account both the funds in hand, as the funds allocated in protocols.
     */
    function balanceOf() public view override returns (uint256 balance) {
        //todo return balance
    }

    /**
     * @dev Function that has to be called as part of strat migration. It sends all the available funds back to the
     *      vault, ready to be migrated to the new strat.
     */
    function retireStrat() external {
        require(msg.sender == vault, '!vault');
        //todo withdraw funds
        uint256 stakedTokenBal = IERC20(stakedToken).balanceOf(address(this));
        IERC20(stakedToken).safeTransfer(vault, stakedTokenBal);
    }

    /**
     * @dev Pauses deposits. Withdraws all funds, leaving rewards behind
     *      Can only be called by strategist or owner.
     */
    function panic() public {
        _onlyStrategistOrOwner();
        pause();
        // todo withdraw funds asap
    }

    /**
     * @dev Pauses the strat. Can only be called by strategist or owner.
     */
    function pause() public {
        _onlyStrategistOrOwner();
        _pause();
        _removeAllowances();
    }

    /**
     * @dev Unpauses the strat. Can only be called by strategist or owner.
     */
    function unpause() external {
        _onlyStrategistOrOwner();
        _unpause();

        _giveAllowances();

        deposit();
    }

    /**
     * @dev Set allowance for token transfers
     */
    function _giveAllowances() internal {
        //todo approve to max
    }

    /**
     * @dev Set all allowances to 0
     */
    function _removeAllowances() internal {
        //todo remove all allowances
    }
}

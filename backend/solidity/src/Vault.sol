// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "src/ERC4626Fees.sol";
import "src/FearAndGreedIndexConsumer.sol";
import "src/interfaces/IAgent.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is ERC4626Fees, FearAndGreedIndexConsumer {
    IERC20 immutable USDC = IERC20(0xB6076C93701D6a07266c31066B298AeC6dd65c2d);
    IAgent immutable AgentContract;

    address payable public vaultOwner;
    uint256 public amountReserves = 0;
    uint256 public amountDeployed = 0;

    event LiquidityRequested(uint256 amount);

    constructor(
        address _agentContract
    ) ERC4626(USDC) ERC20("vaultUSDC", "vUSDC") {
        vaultOwner = payable(msg.sender);
        AgentContract = IAgent(_agentContract);
    }

    function deposit(
        uint256 _amountIn,
        address receiver
    ) public override returns (uint256) {
        require(
            _amountIn <= maxDeposit(receiver),
            "ERC4626: deposit more than max"
        );

        uint256 shares = previewDeposit(_amountIn);
        _deposit(_msgSender(), receiver, _amountIn, shares);

        uint256 vaultBalance = USDC.balanceOf(address(this));
        uint256 deployAmount = (vaultBalance * 8000) / 10000; // 80%
        afterDeposit(deployAmount);

        return shares;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256) {
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) {
            revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        }
        // uint256 currentBalance = USDC.balanceOf(address(this));
        // if (currentBalance < assets) {           // need to figure out how to run requestLiquidity in this func
        //     uint256 neededAmount = assets - currentBalance;
        //     requestLiquidity(neededAmount);
        // }

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function requestLiquidity(uint256 _amountIn) external {
        AgentContract.withdrawTokens(_amountIn);
        amountDeployed -= _amountIn;
        amountReserves = USDC.balanceOf(address(this));
        emit LiquidityRequested(_amountIn);
    }

    function afterDeposit(uint256 deployedAmount) internal {
        USDC.transfer(address(AgentContract), deployedAmount);
        amountDeployed += deployedAmount;
        amountReserves = USDC.balanceOf(address(this));
    }

    function _entryFeeBasisPoints() internal view override returns (uint256) {
        uint fearNGreed = index;

        if (fearNGreed >= 80) {
            // Extreme Greed
            return 150;
        } else if (fearNGreed >= 60) {
            // Greed
            return 125;
        } else if (fearNGreed >= 40) {
            // Neutral
            return 100;
        } else if (fearNGreed >= 20) {
            // Fear
            return 75;
        } else {
            // Extreme Fear
            return 50;
        }
    }

    function _entryFeeRecipient() internal view override returns (address) {
        return vaultOwner;
    }
}

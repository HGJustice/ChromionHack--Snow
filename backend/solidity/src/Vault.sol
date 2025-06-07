// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "contracts/ERC4626Fees.sol";
import "contracts/FearAndGreedIndexConsumer.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "contracts/interfaces/IAgent.sol";

contract Vault is ERC4626Fees, FearAndGreedIndexConsumer {
    IERC20 immutable USDC = IERC20(0xB6076C93701D6a07266c31066B298AeC6dd65c2d);

    address payable public vaultOwner;
    address payable public agent;
    uint256 public amountReserves = 0;
    uint256 public amountDeployed = 0;

    constructor(address _aiAgent) ERC4626(USDC) ERC20("vaultUSDC", "vUSDC") {
        vaultOwner = payable(msg.sender);
        agent = payable(_aiAgent);
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

    function afterDeposit(uint256 deployedAmount) internal {
        USDC.transfer(agent, deployedAmount);
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

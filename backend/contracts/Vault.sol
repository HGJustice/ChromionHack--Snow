// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "contracts/ERC4626Fee.sol";
import "contracts/FearAndGreedIndexConsumer.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is ERC4626Fees, FearAndGreedIndexConsumer {
    address payable public vaultOwner;
    address payable public aiAgent;
    uint256 public amountReserves = 0;
    uint256 public amountDeployed = 0;

    constructor(
        IERC20 _asset,
        address _aiAgent
    ) ERC4626(_asset) ERC20("", "") {
        vaultOwner = payable(msg.sender);
        aiAgent = payable(_aiAgent);
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public override returns (uint256) {
        require(
            assets <= maxDeposit(receiver),
            "ERC4626: deposit more than max"
        );

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        uint256 vaultBalance = IERC20(asset()).balanceOf(address(this));
        uint256 deployedAmount = (vaultBalance * 8000) / 10000; // 80%
        afterDeposit(assets, deployedAmount);

        return shares;
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

    function afterDeposit(uint256 assets, uint256 deployedAmount) internal {
        IERC20(asset()).transfer(aiAgent, deployedAmount);
        amountDeployed += deployedAmount;
        amountReserves += (assets - deployedAmount);
    }
}

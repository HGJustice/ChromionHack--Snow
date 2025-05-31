// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "contracts/ERC4626Fee.sol";
import "contracts/FearAndGreedIndexConsumer.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is ERC4626Fees, FearAndGreedIndexConsumer {
    address payable public vaultOwner;
    address payable public aiAgent;
    uint256 public feeRate;

    constructor(
        IERC20 _asset,
        uint256 _feeRate,
        address _aiAgent
    ) ERC4626(_asset) ERC20("", "") {
        vaultOwner = payable(msg.sender);
        feeRate = _feeRate;
        aiAgent = payable(_aiAgent);
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

    function deposit(
        uint256 assets,
        address receiver
    ) public virtual override returns (uint256) {
        require(
            assets <= maxDeposit(receiver),
            "ERC4626: deposit more than max"
        );

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);
        afterDeposit(assets, shares);

        return shares;
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual override returns (uint256) {
        require(
            assets <= maxWithdraw(owner),
            "ERC4626: withdraw more than max"
        );

        uint256 shares = previewWithdraw(assets);
        beforeWithdraw(assets, shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}
}

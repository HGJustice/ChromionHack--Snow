// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "contracts/ERC4626Fee.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is ERC4626Fees {
    address payable public vaultOwner;
    uint256 public feeRate;

    constructor(IERC20 _asset, uint256 _feeRate) ERC4626(_asset) ERC20("", "") {
        vaultOwner = payable(msg.sender);
        feeRate = _feeRate;
    }

    function _entryFeeBasisPoints() internal view override returns (uint256) {
        return feeRate;
    }

    function _entryFeeRecipient() internal view override returns (address) {
        return vaultOwner;
    }

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}
}

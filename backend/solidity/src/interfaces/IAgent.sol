// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface IAgent {
    function emergencyLiquidityWithdraw(uint256 usdcAmount) external;
}

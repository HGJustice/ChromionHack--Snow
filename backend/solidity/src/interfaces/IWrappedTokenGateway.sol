// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IWrappedTokenGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(address pool, uint256 amount, address to) external;
}

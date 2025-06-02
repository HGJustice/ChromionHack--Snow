// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

interface IWrappedTokenGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(address pool, uint256 amount, address to) external;
}

contract MarketInteractions {
    IPool public immutable POOL;
    IWrappedTokenGateway public immutable WRAPPED_TOKEN_GATEWAY;

    constructor(address _addressPool, address _wrappedTokenGateway) {
        POOL = IPool(_addressPool);
        WRAPPED_TOKEN_GATEWAY = IWrappedTokenGateway(_wrappedTokenGateway);
    }

    // fuji pool address : 0x8B9b2AF4afB389b4a70A474dfD4AdCD4a302bb40
    // fuji wethgateway : 0x3d2ee1AB8C3a597cDf80273C684dE0036481bE3a
    function supplyLiquidity() external payable {
        WRAPPED_TOKEN_GATEWAY.depositETH{value: msg.value}(
            address(POOL),
            address(this),
            0
        );
    }

    function withdrawLiquidity(
        address _tokenAddress,
        uint256 _amount
    ) external returns (uint256) {
        return POOL.withdraw(_tokenAddress, _amount, address(this));
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILBRouter.sol";
import "./interfaces/IWrappedTokenGateway.sol";

contract Agent {
    ILBRouter router = ILBRouter(0x18556DA13313f3532c54711497A8FedAC273220E);
    IERC20 USDC = IERC20(0xB6076C93701D6a07266c31066B298AeC6dd65c2d);
    IERC20 WAVAX = IERC20(0xd00ae08403B9bbb9124bB305C09058E32C39A48c);

    IPool immutable POOL;
    IWrappedTokenGateway immutable WRAPPED_TOKEN_GATEWAY;

    constructor() {
        POOL = IPool(0x8B9b2AF4afB389b4a70A474dfD4AdCD4a302bb40);
        WRAPPED_TOKEN_GATEWAY = IWrappedTokenGateway(0x3d2ee1AB8C3a597cDf80273C684dE0036481bE3a);
    }

    function swapUSDCForAVAX(uint128 _amountIn) external {
        USDC.transferFrom(msg.sender, address(this), _amountIn);
        USDC.approve(address(router), _amountIn);

        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = USDC;
        tokenPath[1] = WAVAX;

        uint256[] memory pairBinSteps = new uint256[](1);
        pairBinSteps[0] = 20;

        ILBRouter.Version[] memory versions = new ILBRouter.Version[](1);
        versions[0] = ILBRouter.Version.V2_1;

        ILBRouter.Path memory path;
        path.pairBinSteps = pairBinSteps;
        path.versions = versions;
        path.tokenPath = tokenPath;

        router.swapExactTokensForNATIVE(
            _amountIn,
            0,
            path,
            msg.sender,
            block.timestamp + 1
        );
    }

    function swapAVAXforUSDC(uint128 _amountIn) external payable {
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = WAVAX;
        tokenPath[1] = USDC;

        uint256[] memory pairBinSteps = new uint256[](1);
        pairBinSteps[0] = 20;

        ILBRouter.Version[] memory versions = new ILBRouter.Version[](1);
        versions[0] = ILBRouter.Version.V2_1;

        ILBRouter.Path memory path;
        path.pairBinSteps = pairBinSteps;
        path.versions = versions;
        path.tokenPath = tokenPath;

        router.swapExactNATIVEForTokens{value: _amountIn}(
            0,
            path,
            msg.sender,
            block.timestamp + 1
        );
    }

    function supplyAaveLiquidity() external payable {
        WRAPPED_TOKEN_GATEWAY.depositETH{value: msg.value}(address(POOL), msg.sender, 0);
    }

    function withdrawAaveLiquidity(uint256 _amount) external {
        WRAPPED_TOKEN_GATEWAY.withdrawETH(address(POOL), _amount, msg.sender);
    }

    receive() external payable {}
}

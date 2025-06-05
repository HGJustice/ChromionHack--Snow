// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILBRouter.sol";
import "./interfaces/IWrappedTokenGateway.sol";

contract Agent {
    ILBRouter immutable router =
        ILBRouter(0x18556DA13313f3532c54711497A8FedAC273220E);
    IERC20 immutable USDC = IERC20(0xB6076C93701D6a07266c31066B298AeC6dd65c2d); //Trader Joe
    IERC20 immutable WAVAX = IERC20(0xd00ae08403B9bbb9124bB305C09058E32C39A48c);

    IPool immutable POOL = IPool(0x8B9b2AF4afB389b4a70A474dfD4AdCD4a302bb40);
    IWrappedTokenGateway immutable WRAPPED_TOKEN_GATEWAY =
        IWrappedTokenGateway(0x3d2ee1AB8C3a597cDf80273C684dE0036481bE3a);
    IERC20 immutable aFUJWAVAX =
        IERC20(0x50902e21C8CfB5f2e45127c1Bbcd6B985119b433); //AAVE

    address payable owner;

    error NotOwner();

    event swappedUSDCforAVAX(uint256 usdcAmountIn, uint256 avaxAmountOut);
    event swappedAVAXforUSDC(uint256 avaxAmountIn, uint256 usdcAmountOut);
    event liquiditySuppliedAAVE(uint256 avaxAmount, uint256 aTokensReceived);
    event liquidityWithdrawnAAVE(
        uint256 aTokensWithdrawn,
        uint256 avaxReceived
    );

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function swapUSDCForAVAX() external onlyOwner {
        uint256 usdcAmountIn = USDC.balanceOf(address(this));
        uint256 avaxBalanceBefore = address(this).balance;
        USDC.approve(address(router), USDC.balanceOf(address(this)));

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
            USDC.balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp + 1
        );

        uint256 avaxAmountOut = address(this).balance - avaxBalanceBefore;
        emit swappedUSDCforAVAX(usdcAmountIn, avaxAmountOut);
    }

    function swapAVAXforUSDC() external onlyOwner {
        uint256 avaxAmountIn = address(this).balance;
        uint256 usdcBalanceBefore = USDC.balanceOf(address(this));

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

        router.swapExactNATIVEForTokens{value: address(this).balance}(
            0,
            path,
            address(this),
            block.timestamp + 1
        );

        uint256 usdcAmountOut = USDC.balanceOf(address(this)) -
            usdcBalanceBefore;
        emit swappedAVAXforUSDC(avaxAmountIn, usdcAmountOut);
    }

    function supplyAaveLiquidity() external onlyOwner {
        uint256 avaxAmount = address(this).balance;
        uint256 aTokensBefore = aFUJWAVAX.balanceOf(address(this));

        WRAPPED_TOKEN_GATEWAY.depositETH{value: address(this).balance}(
            address(POOL),
            address(this),
            0
        );

        uint256 aTokensReceived = aFUJWAVAX.balanceOf(address(this)) -
            aTokensBefore;
        emit liquiditySuppliedAAVE(avaxAmount, aTokensReceived);
    }

    function withdrawAaveLiquidity() external onlyOwner {
        uint256 aTokensWithdrawn = aFUJWAVAX.balanceOf(address(this));
        uint256 avaxBalanceBefore = address(this).balance;

        aFUJWAVAX.approve(
            address(WRAPPED_TOKEN_GATEWAY),
            aFUJWAVAX.balanceOf(address(this))
        );
        WRAPPED_TOKEN_GATEWAY.withdrawETH(
            address(POOL),
            aFUJWAVAX.balanceOf(address(this)),
            address(this)
        );

        uint256 avaxReceived = address(this).balance - avaxBalanceBefore;
        emit liquidityWithdrawnAAVE(aTokensWithdrawn, avaxReceived);
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "tx failed");
    }

    receive() external payable {}
}

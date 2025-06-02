// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILBRouter {
    enum Version {
        V1,
        V2,
        V2_1,
        V2_2
    }

    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function swapExactTokensForNATIVE(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function getSwapOut(
        address pair,
        uint128 amountIn,
        bool swapForY
    )
        external
        view
        returns (
            uint128 amountInLeft,
            uint128 amountOut,
            uint128 amountOutLeft
        );
}

contract SimpleSwap {
    ILBRouter public router =
        ILBRouter(0x18556DA13313f3532c54711497A8FedAC273220E);
    IERC20 public USDC = IERC20(0xB6076C93701D6a07266c31066B298AeC6dd65c2d);
    IERC20 public WAVAX = IERC20(0xd00ae08403B9bbb9124bB305C09058E32C39A48c);
    address public pair = 0x88F36a6B0e37E78d0Fb1d41B07A47BAD3D995453; // AVAX-USDC 20bps pool

    function swapUSDCForAVAX(uint128 amountIn) external {
        // Transfer USDC from user
        USDC.transferFrom(msg.sender, address(this), amountIn);

        // Approve router
        USDC.approve(address(router), amountIn);

        // Setup path exactly like docs
        IERC20[] memory tokenPath = new IERC20[](2);
        tokenPath[0] = USDC;
        tokenPath[1] = WAVAX;

        uint256[] memory pairBinSteps = new uint256[](1);
        pairBinSteps[0] = 20;

        ILBRouter.Version[] memory versions = new ILBRouter.Version[](1);
        versions[0] = ILBRouter.Version.V2_1;

        ILBRouter.Path memory path; // instanciate and populate the path to perform the swap.
        path.pairBinSteps = pairBinSteps;
        path.versions = versions;
        path.tokenPath = tokenPath;

        // (, uint256 amountOut, ) = router.getSwapOut(pair, amountIn, true);
        // uint256 amountOutWithSlippage = amountOut * 99 / 100; // We allow for 1% slippage
        router.swapExactTokensForNATIVE(
            amountIn,
            0,
            path,
            msg.sender,
            block.timestamp + 1
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ILBRouter.sol";

contract Agent {
    ILBRouter public router =
        ILBRouter(0x18556DA13313f3532c54711497A8FedAC273220E);
    IERC20 public USDC = IERC20(0xB6076C93701D6a07266c31066B298AeC6dd65c2d);
    IERC20 public WAVAX = IERC20(0xd00ae08403B9bbb9124bB305C09058E32C39A48c);

    function swapUSDCForAVAX(uint128 amountIn) external {
        USDC.transferFrom(msg.sender, address(this), amountIn);

        USDC.approve(address(router), amountIn);

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
            amountIn,
            0,
            path,
            msg.sender,
            block.timestamp + 1
        );
    }
}

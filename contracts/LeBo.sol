//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IERC20.sol";
import "hardhat/console.sol";

contract LeBo {
    IUniswapV2Router constant router = IUniswapV2Router(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    IERC20 constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 constant DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    mapping (address => uint256) wethDeposited;
    mapping (address => uint256) wethBorrowed;
    mapping (address => uint256) daiDeposited;
    mapping (address => uint256) daiBorrowed;

    function depositWETH(uint256 amount) public { 
        require(WETH.transferFrom(msg.sender, address(this), amount), "u broke, bruh");
        wethDeposited[msg.sender] += amount;
        printStats();
    }

    function depositDAI(uint256 amount) public { 
        require(DAI.transferFrom(msg.sender, address(this), amount), "u broke, bruh");
        daiDeposited[msg.sender] += amount;
        printStats();
    }  

    function borrowWETH(uint256 amount) public {
        wethBorrowed[msg.sender] += amount;
        require(WETH.transfer(msg.sender, amount), "we broke, bruh");
        require(isSolvent(msg.sender), "this ain't a charity");
        printStats();
    }

    function borrowDAI(uint256 amount) public {
        daiBorrowed[msg.sender] += amount;
        require(DAI.transfer(msg.sender, amount), "we broke, bruh");
        require(isSolvent(msg.sender), "this ain't a charity");
        printStats();
    }

    function liquidate(address user) public {
        require(!isSolvent(user), "swiper no swiping");
        require(WETH.transferFrom(msg.sender, address(this), wethBorrowed[user]), "gib permission, ser");
        require(DAI.transferFrom(msg.sender, address(this), daiBorrowed[user]), "gib permission, ser");
        require(WETH.transfer(msg.sender, wethDeposited[user]), "impossibru");
        require(DAI.transfer(msg.sender, daiDeposited[user]), "impossibru");
        printStats();
    }

    function isSolvent(address user) public view returns (bool) {
        uint256 collateralValue = wethDeposited[user] * ethPrice() + daiDeposited[user];
        // 90% LTV
        uint256 maxBorrow = collateralValue * 100 / 90;
        uint256 borrowed = wethBorrowed[user] * ethPrice() + daiBorrowed[user];
        return maxBorrow >= borrowed;
    }

    function ethPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(DAI);
        return router.getAmountsOut(1, path)[1];
    }

    function printStats() public view {
        console.log("User: ", msg.sender);
        console.log("WETH deposited:", wethDeposited[msg.sender] / 1 ether);
        console.log("WETH borrowed:", wethBorrowed[msg.sender] / 1 ether);
        console.log("WETH price:", ethPrice());
        console.log("DAI deposited:", daiDeposited[msg.sender] / 1 ether);
        console.log("DAI borrowed:", daiBorrowed[msg.sender] / 1 ether);
        console.log("---------------------------------------------------------------------------------");
    }
}

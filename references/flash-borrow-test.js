const hre = require("hardhat");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
chai.use(solidity);
const { expect } = chai;

const moveTimeForward = async (seconds) => {
  await network.provider.send("evm_increaseTime", [seconds]);
  await network.provider.send("evm_mine");
};

describe("Vaults", function () {
  const wantAddress = "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75"; // USDC
  const wantHolder = "0x93C08a3168fC469F3fC165cd3A471D19a37ca19e";
  const paymentRouterAddress = "0x603e60D22af05ff77FDCf05c063f582C40e55aae";
  const strategistAddress = "0x1A20D7A31e5B3Bc5f02c8A146EF6f394502a10c4";

  const gUSDC = "0xe578C856933D8e1082740bf7661e379Aa2A30b26";
  const targetLtv = 7800;

  let Vault;
  let Strategy;
  let Treasury;
  let Usdc;
  let PaymentRouter;

  let vault;
  let strategy;
  let treasury;
  let paymentRouter;

  let want;
  let self;
  let selfAddress;
  let owner;
  let strategist;

  beforeEach(async function () {
    // reset network
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: "https://late-wild-fire.fantom.quiknode.pro/",
          },
        },
      ],
    });

    // get signers
    [owner] = await ethers.getSigners();
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [wantHolder],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [strategistAddress],
    });
    self = await ethers.provider.getSigner(wantHolder);
    strategist = await ethers.provider.getSigner(strategistAddress);
    selfAddress = await self.getAddress();

    // get artifacts
    Strategy = await ethers.getContractFactory("ReaperAutoCompoundFlashBorrow");
    Vault = await ethers.getContractFactory("ReaperVaultv1_3");
    Treasury = await ethers.getContractFactory("ReaperTreasury");
    Usdc = await ethers.getContractFactory("Usdc");
    PaymentRouter = await ethers.getContractFactory("PaymentRouter");

    // deploy contracts
    treasury = await Treasury.deploy();
    want = await Usdc.attach(wantAddress);
    paymentRouter = await PaymentRouter.attach(paymentRouterAddress);
    vault = await Vault.deploy(
      wantAddress,
      "USDC GEIST Crypt",
      "rf-gUSDC",
      432000,
      0,
      ethers.constants.MaxUint256
    );

    strategy = await Strategy.deploy(
      vault.address,
      [treasury.address, paymentRouterAddress],
      [strategistAddress],
      gUSDC,
      targetLtv
    );
    await strategy.deployed();
    await vault.initialize(strategy.address);
    await paymentRouter
      .connect(strategist)
      .addStrategy(strategy.address, [strategistAddress], [100]);

    await want
      .connect(self)
      .approve(vault.address, ethers.constants.MaxUint256);
  });

  describe("Deploying the vault and strategy", function () {
    it("should initiate vault with a 0 balance", async function () {
      const totalBalance = await vault.balance();
      const availableBalance = await vault.available();
      const pricePerFullShare = await vault.getPricePerFullShare();

      expect(totalBalance).to.equal(ethers.constants.Zero);
      expect(availableBalance).to.equal(ethers.constants.Zero);
      expect(pricePerFullShare).to.equal(ethers.utils.parseEther("1"));
    });
  });

  describe("Vault Tests", function () {
    it("should allow deposits and account for them correctly", async function () {
      const userBalance = await want.balanceOf(selfAddress);
      const initialVaultBalance = await vault.balance();
      const depositAmount = userBalance.div(2);

      await vault.connect(self).deposit(depositAmount);
      const newVaultBalance = await vault.balance();
      const newUserBalance = await want.balanceOf(selfAddress);
      const deductedAmount = userBalance.sub(newUserBalance);

      expect(initialVaultBalance).to.equal(ethers.constants.Zero);
      expect(newVaultBalance).to.equal(depositAmount);
      expect(deductedAmount).to.equal(depositAmount);
    });

    it("should allow withdrawals", async function () {
      const userBalance = await want.balanceOf(selfAddress);
      const depositAmount = userBalance.div(2);
      await vault.connect(self).deposit(depositAmount);

      const withdrawAmount = depositAmount; // .div(4);
      await vault.connect(self).withdraw(withdrawAmount);

      const actualUserBalanceAfterWithdraw = await want.balanceOf(selfAddress);
      const expectedUserBalanceAfterWithdraw = userBalance
        .sub(depositAmount)
        .add(withdrawAmount);

      expect(actualUserBalanceAfterWithdraw).to.be.gte(
        expectedUserBalanceAfterWithdraw.mul(9950).div(10000)
      );
      console.log(
        `Withdraw fees paid is ${userBalance
          .sub(depositAmount)
          .add(withdrawAmount)
          .sub(actualUserBalanceAfterWithdraw)
          .mul(10000)
          .div(withdrawAmount)} basis points.`
      );
    });

    it("should provide yield", async function () {
      const timeToSkip = 3600;
      const initialUserBalance = await want.balanceOf(selfAddress);
      const depositAmount = initialUserBalance.div(10);

      await vault.connect(self).deposit(depositAmount);
      const initialVaultBalance = await vault.balance();

      await strategy
        .connect(strategist)
        .updateHarvestLogCadence(timeToSkip / 2);

      const numHarvests = 2;
      for (let i = 0; i < numHarvests; i++) {
        await moveTimeForward(timeToSkip);
        await strategy.harvest();
      }

      const finalVaultBalance = await vault.balance();
      expect(finalVaultBalance).to.be.gt(initialVaultBalance);

      const averageAPR = await strategy.averageAPRAcrossLastNHarvests(
        numHarvests
      );
      console.log(
        `Average APR across ${numHarvests} harvests is ${averageAPR} basis points.`
      );
    });
  });
});

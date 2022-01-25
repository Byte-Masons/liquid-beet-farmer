const hre = require("hardhat");
const chai = require("chai");
const { solidity } = require("ethereum-waffle");
chai.use(solidity);
const { expect } = chai;
const wantAbi = require("../abi/bpt-a-late-quartet.json");

const moveTimeForward = async (seconds) => {
    await network.provider.send("evm_increaseTime", [seconds]);
    await network.provider.send("evm_mine");
}

describe("Vaults", () => {
    const wantAddress = "0xf3A602d30dcB723A74a0198313a7551FEacA7DAc"; // bpToken - A Late Quartet
    const wantHolderAddress = "0xf335947Fd2BB811cEa6fBce43847fcEff8Ad2e62"; // pray you don't have to change that, or buy some yourself
    const paymentRouterAddress = "0x603e60D22af05ff77FDCf05c063f582C40e55aae";
    const strategistAddress = "0x1E71AEE6081f62053123140aacC7a06021D77348";

    //Underlying tokens addresses
    const usdcAddress = "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75";
    const wftmAddress = "0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83";
    const wbtcAddress = "0x321162Cd933E2Be498Cd2267a90534A804051b11";
    const wethAddress = "0x74b23882a30290451A17c44f4F05243b6b58C76d";

    let Vault;
    let Strategy;
    let Treasury;
    let Want;
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

    beforeEach( async () => {
        //reset network
        await network.provider.request({
            method: "hardhat_reset",
            params: [
                {
                    forking: {
                        jsonRpcUrl: "https://late-wild-fire.fantom.quiknode.pro/",
                        // jsonRpcUrl: "https://rpc.ftm.tools/",
                    },
                },
            ],
        });

        // get signers
        [owner] = await ethers.getSigners();
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [wantHolderAddress],
        });
        await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [strategistAddress],
        });
        self = await ethers.provider.getSigner(wantHolderAddress);
        strategist = await ethers.provider.getSigner(strategistAddress);
        selfAddress = await self.getAddress();

        // get artifacts
        Strategy = await ethers.getContractFactory("ReaperAutoCompound_LiquidV2_Beethoven");
        Vault = await ethers.getContractFactory("ReaperVaultv1_3");
        Treasury = await ethers.getContractFactory("ReaperTreasury");
        Want = await ethers.getContractFactory("Usdc");
        PaymentRouter = await ethers.getContractFactory("PaymentRouter");

        //deploy contracts
        treasury = await Treasury.deploy();
        // want = new ethers.Contract(wantAddress, wantAbi, self);
        want = await Want.attach(wantAddress);
        paymentRouter = await PaymentRouter.attach(paymentRouterAddress);
        vault = await Vault.deploy(
            wantAddress,
            "A Late Quartet Beethoven-Liquid Crypt",
            "rfLQUARTET",
            432000,
            0,
            ethers.constants.MaxUint256
        );

        // IMPORTANT : routes must be provided in the pool's own token order
        strategy = await Strategy.deploy(
            vault.address,
            [treasury.address, paymentRouterAddress],
            [strategistAddress],
            wantAddress,
            31,
            [2500,2500,2500,2500],
            [
                [wftmAddress, usdcAddress],
                [wftmAddress],
                [wftmAddress, wbtcAddress],
                [wftmAddress, wethAddress]
            ]
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

    xdescribe("Deploying the vault and strategy", () => {
        it("should initiate a vault with a 0 balance", async () => {
            const totalBalance = await vault.balance();
            const availableBalance = await vault.available();
            const pricePerFullShare = await vault.getPricePerFullShare();

            expect(totalBalance).to.equal(ethers.constants.Zero);
            expect(availableBalance).to.equal(ethers.constants.Zero);
            expect(pricePerFullShare).to.equal(ethers.utils.parseEther("1"));
        });
    });

    describe("Vault Tests", () => {
        xit("should allow deposits and account for them correctly", async () => {
            const userBalance = await want.balanceOf(selfAddress);
            const initialVaultBalance = await vault.balance();
            const depositAmount = userBalance.div(2);

            await vault.connect(self).deposit(depositAmount);
            const newVaultBalance = await vault.balance();
            const newUserBalance = await want.balanceOf(selfAddress);
            const deductedAmount = userBalance.sub(newUserBalance);

            console.log(`initialVaultBalance ${initialVaultBalance.toString()} = ethers.constants.Zero ${ethers.constants.Zero}`);
            console.log(`newVaultBalance ${newVaultBalance.toString()} = depositAmount ${depositAmount}`);
            console.log(`deductedAmount ${deductedAmount.toString()} = depositAmount ${depositAmount.toString()}`);
            expect(initialVaultBalance).to.equal(ethers.constants.Zero);
            expect(newVaultBalance).to.equal(depositAmount);
            expect(deductedAmount).to.equal(depositAmount);
        });

        xit("should allow withdrawals", async () => {
            const userBalance = await want.balanceOf(selfAddress);
            const depositAmount = userBalance.div(2);
            await vault.connect(self).deposit(depositAmount);
      
            const withdrawAmount = depositAmount; // .div(4);
            await vault.connect(self).withdraw(withdrawAmount);
      
            const actualUserBalanceAfterWithdraw = await want.balanceOf(selfAddress);
            const expectedUserBalanceAfterWithdraw = userBalance
              .sub(depositAmount)
              .add(withdrawAmount);
            
            console.log(
                `actualUserBalanceAfterWithdraw ${actualUserBalanceAfterWithdraw} > expectedUserBalanceAfterWithdraw.mul(9950).div(10000) ${expectedUserBalanceAfterWithdraw.mul(9950).div(10000)}`
            );
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

        it("should provide yield", async () => {
            const timeToSkip = 30 * 24 * 60 * 60;
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
              console.log('ABOUT TO FAIL');
              await strategy.harvest();
              console.log('DID NOT FAIL');
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
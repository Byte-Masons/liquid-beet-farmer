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
        Strategy = await ethers.getContractFactory("ReaperAutoCompoundLiquidv2Beethoven");
        Vault = await ethers.getContractFactory("ReaperVaultv1_3");
        Treasury = await ethers.getContractFactory("ReaperTreasury");
        Want = new ethers.Contract(wantAddress, wantAbi, self);
        PaymentRouter = await ethers.getContractFactory("PaymentRouter");
    });
});
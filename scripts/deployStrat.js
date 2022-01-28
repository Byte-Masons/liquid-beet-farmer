const deployStrategy = async (vaultAddress) => {
  const Strategy = await ethers.getContractFactory("ReaperAutoCompound_LiquidV2_Beethoven");
  const treasuryAddress = "0x0e7c5313E9BB80b654734d9b7aB1FB01468deE3b";
  const paymentSplitterAddress = "0x63cbd4134c2253041F370472c130e92daE4Ff174";
  const strategists = ["0x1E71AEE6081f62053123140aacC7a06021D77348","0x81876677843D00a7D792E1617459aC2E93202576","0x1A20D7A31e5B3Bc5f02c8A146EF6f394502a10c4"];
  const wantAddress = "0xf3A602d30dcB723A74a0198313a7551FEacA7DAc";
  const poolId = 31;

  const strategy = await Strategy.deploy(
    vaultAddress,
    [treasuryAddress,paymentSplitterAddress],
    strategists,
    wantAddress,
    poolId
  );
  await strategy.deployed();
  console.log("Strategy deployed to:", strategy.address);
  return strategy.address;
}

async function main() {
  const vaultAddress = "0xbdf94B9D813AE4B54D9B221C6fd003AF2e1B8432";
  const strategyAddress = await deployStrategy(vaultAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

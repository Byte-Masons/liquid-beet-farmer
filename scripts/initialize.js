async function main() {
  const vaultAddress = "0xbdf94B9D813AE4B54D9B221C6fd003AF2e1B8432";
  const strategyAddress = '0x850aB9BCB1a38808526f682466683947000BFDe3';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');
  const vault = Vault.attach(vaultAddress);

  await vault.initialize(strategyAddress);
  console.log('Vault initialized');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

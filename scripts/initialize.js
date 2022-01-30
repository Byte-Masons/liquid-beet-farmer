async function main() {
  const vaultAddress = "0x5F5181128C19D9d08c2c25eC802e656F1E966dA4";
  const strategyAddress = '0x5ee8E0558D81604439fC67C389B3B8c8a909607C';

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

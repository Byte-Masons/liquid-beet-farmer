async function main() {
  const vaultAddress = '0xE9A991724054C95ABb9E35410D1d38A7440067a9';
  const strategyAddress = '0xEe12DE8FDb15c0a90A9150Ed03Adf45334B597aa';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_4');
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

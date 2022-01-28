async function main() {
  const vaultAddress = "0x25af6Bb8b9308b3B187F4c67344031b4bBdf8d44";
  const strategyAddress = '0xe548E2428A32c317DbbFaB0716C9329E1F435034';

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

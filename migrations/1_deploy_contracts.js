const Vault = artifacts.require("Vault");
const CurveStrategy = artifacts.require("CurveStrategy");

module.exports = async function(deployer) {
  const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const POOL = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7";
  const GAUGE = "0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A";
  await deployer.deploy(Vault, "DAI vault", "pDAI");
  const vaultInstance = await Vault.deployed();
  await deployer.deploy(CurveStrategy, DAI, POOL, GAUGE, vaultInstance.address, 3);

  const strategyInstance = await CurveStrategy.deployed();

  await vaultInstance.setStrategy(strategyInstance.address);
};

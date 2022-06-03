const Vault = artifacts.require("Vault");
const CurveStrategy = artifacts.require("CurveStrategy");
const PriceOracle = artifacts.require("PriceOracle");

module.exports = async function(deployer) {
  const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
  const POOL = "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7";
  const GAUGE = "0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A";

  const CRV_USD_ORACLE = "0xcd627aa160a6fa45eb793d19ef54f5062f20f33f";
  const DAI_USD_ORACLE = "0xaed0c38402a5d19df6e4c03f4e2dced6e29c1ee9";

  await deployer.deploy(Vault, "DAI vault", "pDAI");
  const vaultInstance = await Vault.deployed();
  await deployer.deploy(CurveStrategy, DAI, POOL, GAUGE, vaultInstance.address, 3);

  const strategyInstance = await CurveStrategy.deployed();
  await vaultInstance.setStrategy(strategyInstance.address);

  await deployer.deploy(PriceOracle);
  const oracleInstance = await PriceOracle.deployed();

  // set chainlink feeds
  await oracleInstance.setFeed("CRV", CRV_USD_ORACLE);
  await oracleInstance.setFeed("DAI", DAI_USD_ORACLE);

  await vaultInstance.setOracle(oracleInstance.address);
};

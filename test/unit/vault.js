const { expectRevert, expectEvent, constants } = require("@openzeppelin/test-helpers");
const Vault = artifacts.require("Vault");

contract("Vault", (accounts) => {
  let vaultInstance = null;
  const deployer = accounts[0];
  const testAccount = accounts[1];

  before(async () => {
    vaultInstance = await Vault.deployed();
  });

  it('Should fail if non admin try to call setStrategy()', async () => {
    await expectRevert(
      vaultInstance.setStrategy(constants.ZERO_ADDRESS, { from: testAccount }),
      'Ownable: caller is not the owner'
    );
  });

  it('Admin should be able to call setStrategy()', async () => {
    const tx = await vaultInstance.setStrategy(constants.ZERO_ADDRESS, { from: deployer });
    await expectEvent(tx.receipt, "StrategyUpdated", { newStrategy: constants.ZERO_ADDRESS });
  });
});

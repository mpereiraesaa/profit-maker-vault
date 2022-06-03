require("dotenv").config();
const { expectRevert, constants } = require("@openzeppelin/test-helpers");
const { advanceNBlock } = require('../helpers/utils');
const { mainnet: { DAI: DAI_ADDRESS, USDC: USDC_ADDRESS, USDT: USDT_ADDRESS } } = require("../data/addresses.json");
const Vault = artifacts.require("Vault");
const IERC20 = artifacts.require("IERC20");

const { DAI_WHALE } = process.env;

contract("Vault", (accounts) => {
  let vaultInstance = null;
  let DAI = null;
  let USDC = null;
  let USDT = null;
  const testAccount = accounts[0];
  const testAccount2 = accounts[1];

  const SAMPLE_AMOUNT = "100000000000000000000"

  before(async () => {
    DAI = await IERC20.at(DAI_ADDRESS);
    USDC = await IERC20.at(USDC_ADDRESS);
    USDT = await IERC20.at(USDT_ADDRESS);

    const AMOUNT = web3.utils.toBN("1000000000000000000000");

    // Transfer funds from whale
    await DAI.transfer(testAccount, AMOUNT, { from: DAI_WHALE});

    // Setup vault
    vaultInstance = await Vault.deployed();

    // Approve vault to spend account funds
    await DAI.approve(vaultInstance.address, constants.MAX_UINT256, { from: testAccount});
    await DAI.approve(vaultInstance.address, constants.MAX_UINT256, { from: testAccount2});
  });

  it('User can deposit DAI and mint lp tokens', async () => {
    await vaultInstance.deposit(SAMPLE_AMOUNT, { from: testAccount });
    const lpTokens = await vaultInstance.balanceOf(testAccount);
    assert.equal(lpTokens.toString(), SAMPLE_AMOUNT.toString());
  });

  it('deposit should fail as DAI balance is zero', async () => {
    // await debug(vaultInstance.deposit(SAMPLE_AMOUNT, { from: testAccount2 }), "Dai/insufficient-balance.");
    await expectRevert(vaultInstance.deposit(SAMPLE_AMOUNT, { from: testAccount2 }), "Dai/insufficient-balance.");
  });

  it('withdraw should fail as LP balance is zero', async () => {
    await expectRevert(vaultInstance.withdraw(SAMPLE_AMOUNT, { from: testAccount2 }), "ERC20: burn amount exceeds balance");
  });

  it('vault should deposit funds into curve protocol', async () => {
    const initialInvestedAmount = await vaultInstance.investedBalance();
    await vaultInstance.deposit(SAMPLE_AMOUNT, { from: testAccount });
    const investedBalance = await vaultInstance.investedBalance();
    assert(investedBalance.toString() / 1e18 > initialInvestedAmount.toString() / 1e18);
  });

  it('user can transfer lp tokens', async () => {
    await vaultInstance.transfer(testAccount2, SAMPLE_AMOUNT, { from: testAccount });
    const balance = await vaultInstance.balanceOf(testAccount2);
    assert.equal(balance.toString(), SAMPLE_AMOUNT.toString());
  });

  it('user can withdraw/redeem LP tokens and receive underlying tokens', async () => {
    const lpTokens = await vaultInstance.balanceOf(testAccount2);

    // balances should be initially zero in the 3 coins
    const initialBalanceDAI = await DAI.balanceOf(testAccount2);
    const initialBalanceUSDC = await USDC.balanceOf(testAccount2);
    const initialBalanceUSDT = await USDT.balanceOf(testAccount2);

    await vaultInstance.withdraw(lpTokens, {from: testAccount2});

    const newBalanceDAI = await DAI.balanceOf(testAccount2);
    const newBalanceUSDC = await USDC.balanceOf(testAccount2);
    const newBalanceUSDT = await USDT.balanceOf(testAccount2);

    assert(newBalanceDAI.gt(initialBalanceDAI));
    assert(newBalanceUSDC.gt(initialBalanceUSDC));
    assert(newBalanceUSDT.gt(initialBalanceUSDT));
  });

  it('Vault should harvest and increase exchangeRate', async () => {
    const blocksPerHour = 240;
    await vaultInstance.deposit(SAMPLE_AMOUNT, { from: testAccount });

    const oldExchangeRate = await vaultInstance.exchangeRate();
    const oldTotalBalance = await vaultInstance.totalBalance();

    // Advance 1 hour
    await advanceNBlock(blocksPerHour);
    await vaultInstance.harvest();

    const newExchangeRate = await vaultInstance.exchangeRate();
    const newTotalBalance = await vaultInstance.totalBalance();

    assert(newTotalBalance.gt(oldTotalBalance));
    assert(newExchangeRate.gt(oldExchangeRate));
  });
});

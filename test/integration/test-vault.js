require("dotenv").config();
const { expectRevert } = require("@openzeppelin/test-helpers");
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
  const deployer = accounts[0];
  const testAccount = accounts[1];

  const BASE_AMOUNT = web3.utils.toBN(100*1e18);

  before(async () => {
    DAI = await IERC20.at(DAI_ADDRESS);
    USDC = await IERC20.at(USDC_ADDRESS);
    USDT = await IERC20.at(USDT_ADDRESS);

    // Transfer funds from whale
    await DAI.transfer(deployer, BASE_AMOUNT, { from: DAI_WHALE});
    await DAI.transfer(testAccount, BASE_AMOUNT, { from: DAI_WHALE});

    // Setup vault
    vaultInstance = await Vault.deployed();

    // Approve vault to spend account funds
    await DAI.approve(vaultInstance.address, BASE_AMOUNT, { from: deployer});
    await DAI.approve(vaultInstance.address, BASE_AMOUNT, { from: testAccount});
  });

  it('User can deposit DAI and mint lp tokens', async () => {
    await vaultInstance.deposit(BASE_AMOUNT, { from: deployer });
    const lpTokens = await vaultInstance.balanceOf(deployer);
    assert.equal(lpTokens.toString(), BASE_AMOUNT.toString());
  });

  it('deposit should fail as DAI balance is zero', async () => {
    await DAI.approve(vaultInstance.address, BASE_AMOUNT, { from: accounts[0]});
    await expectRevert(vaultInstance.deposit(BASE_AMOUNT, { from: accounts[0] }), "Dai/insufficient-balance.");
  });

  it('withdraw should fail as LP balance is zero', async () => {
    await expectRevert(vaultInstance.withdraw(BASE_AMOUNT, { from: accounts[0] }), "ERC20: burn amount exceeds balance");
  });

  it('vault should deposit funds into curve protocol', async () => {
    await DAI.approve(vaultInstance.address, BASE_AMOUNT, { from: DAI_HOLDER_ADDRESS});
    const initialInvestedAmount = await vaultInstance.investedBalance();
    await vaultInstance.deposit(BASE_AMOUNT, { from: DAI_HOLDER_ADDRESS });
    const investedBalance = await vaultInstance.investedBalance();
    assert(investedBalance.toString() / 1e18 > initialInvestedAmount.toString() / 1e18);
  });

  it('user can transfer lp tokens', async () => {
    await vaultInstance.transfer(accounts[0], BASE_AMOUNT, { from: DAI_HOLDER_ADDRESS });
    const balance = await vaultInstance.balanceOf(accounts[0]);
    assert.equal(balance.toString(), BASE_AMOUNT.toString());
  });

  it('user can withdraw/redeem LP tokens and receive underlying tokens', async () => {
    const lpTokens = await vaultInstance.balanceOf(accounts[0]);

    // balances should be initially zero in the 3 coins
    const initialBalanceDAI = await DAI.balanceOf(accounts[0]);
    const initialBalanceUSDC = await USDC.balanceOf(accounts[0]);
    const initialBalanceUSDT = await USDT.balanceOf(accounts[0]);

    await vaultInstance.withdraw(lpTokens, {from: accounts[0]});

    const newBalanceDAI = await DAI.balanceOf(accounts[0]);
    const newBalanceUSDC = await USDC.balanceOf(accounts[0]);
    const newBalanceUSDT = await USDT.balanceOf(accounts[0]);

    assert(newBalanceDAI.gt(initialBalanceDAI));
    assert(newBalanceUSDC.gt(initialBalanceUSDC));
    assert(newBalanceUSDT.gt(initialBalanceUSDT));
  });

  it('Vault should harvest and increase exchangeRate', async () => {
    const blocksPerHour = 240;
    await vaultInstance.deposit(BASE_AMOUNT, { from: testAccount });

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

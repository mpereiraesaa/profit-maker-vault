const { time, expectRevert, constants } = require("@openzeppelin/test-helpers");

const Vault = artifacts.require("Vault");
const IERC20 = artifacts.require("IERC20");
const DAI_ADDRESS = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const USDC_ADDRESS = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
const USDT_ADDRESS = '0xdAC17F958D2ee523a2206206994597C13D831ec7';

const DAI_USER_ADDRESS = '0xb527a981e1d415AF696936B3174f2d7aC8D11369';

async function advanceNBlock(n) {
  let startingBlock = await time.latestBlock();
  await time.increase(15 * Math.round(n));
  let endBlock = startingBlock.addn(n);
  await time.advanceBlockTo(endBlock);
}

contract('Vault admin', (accounts) => {
  let vaultInstance = null;
  before(async () => {
    vaultInstance = await Vault.deployed();
  });
  it('Only owner can set a new strategy in vault', async () => {
    await expectRevert(
      vaultInstance.setStrategy(constants.ZERO_ADDRESS, { from: DAI_USER_ADDRESS }),
      'Ownable: caller is not the owner'
    );
    await vaultInstance.setStrategy(constants.ZERO_ADDRESS, { from: accounts[0] });
    const strategy = await vaultInstance.strategy();
    assert.equal(strategy, constants.ZERO_ADDRESS);
  });  
});

contract('Vault basic functionality', (accounts) => {
  let vaultInstance = null;
  let DAI = null;
  let USDC = null;
  let USDT = null;
  before(async () => {
    vaultInstance = await Vault.deployed();
    DAI = await IERC20.at(DAI_ADDRESS);
    USDC = await IERC20.at(USDC_ADDRESS);
    USDT = await IERC20.at(USDT_ADDRESS);
  });
  it('user can deposit DAI and mint lp tokens', async () => {
    const amount = web3.utils.toBN(100*1e18);
    await DAI.approve(vaultInstance.address, amount, { from: DAI_USER_ADDRESS});
    await vaultInstance.deposit(amount, { from: DAI_USER_ADDRESS });
    const lpTokens = await vaultInstance.balanceOf(DAI_USER_ADDRESS);
    assert.equal(lpTokens.toString() / 1e18, 100);
  });
  it('deposit should fail as DAI balance is zero', async () => {
    const amount = web3.utils.toBN(100*1e18);
    await DAI.approve(vaultInstance.address, amount, { from: accounts[0]});
    await expectRevert(vaultInstance.deposit(amount, { from: accounts[0] }), "fail: cannot deposit 0");
  });
  it('withdraw should fail as LP balance is zero', async () => {
    const amount = web3.utils.toBN(100*1e18);
    await expectRevert(vaultInstance.withdraw(amount, { from: accounts[0] }), "fail: cannot withdraw 0");
  });
  it('vault should deposit funds into curve protocol', async () => {
    const amount = web3.utils.toBN(100*1e18);
    await DAI.approve(vaultInstance.address, amount, { from: DAI_USER_ADDRESS});
    const initialInvestedAmount = await vaultInstance.investedBalance();
    await vaultInstance.deposit(amount, { from: DAI_USER_ADDRESS });
    const investedBalance = await vaultInstance.investedBalance();
    assert(investedBalance.toString() / 1e18 > initialInvestedAmount.toString() / 1e18);
  });
  it('user can transfer lp tokens', async () => {
    const amount = await vaultInstance.balanceOf(DAI_USER_ADDRESS);
    await vaultInstance.transfer(accounts[0], amount, { from: DAI_USER_ADDRESS });
    const balance = await vaultInstance.balanceOf(accounts[0]);
    assert.equal(balance.toString(), amount.toString());
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
});

contract('Vault rewards', async (accounts) => {
  let vaultInstance = null;
  let DAI = null;
  let USDC = null;
  let USDT = null;
  before(async () => {
    vaultInstance = await Vault.deployed();
    DAI = await IERC20.at(DAI_ADDRESS);
    USDC = await IERC20.at(USDC_ADDRESS);
    USDT = await IERC20.at(USDT_ADDRESS);
  });
  it('Vault should harvest and increase exchangeRate', async () => {
    const amount = web3.utils.toBN(100*1e18);
    await DAI.transfer(accounts[1], amount, {from: DAI_USER_ADDRESS});

    await DAI.approve(vaultInstance.address, amount, { from: accounts[1]});
    await vaultInstance.deposit(amount, { from: accounts[1] });

    const blocksPerHour = 240;

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
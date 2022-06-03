// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/uniswap/IUniswapV2Router02.sol";
import "./interfaces/ICurve3Pool.sol";
import "./interfaces/ILiquidityGauge.sol";
import "./interfaces/ICurveFiMinter.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IPriceOracle.sol";

contract Vault is ERC20, Ownable {
  using SafeERC20 for IERC20;
  IUniswapV2Router02 private constant _uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  IStrategy private _strategy;
  IPriceOracle public _oracle;

  uint256 public SLIPPAGE = 950;

  event Deposit(address _user, uint256 _underlying_amount, uint256 _shares);
  event Withdraw(address _user, uint256 _lp_amount, uint256 _shares);
  event Claim(uint256 rewards);
  event StrategyUpdated(IStrategy newStrategy);

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

  function setOracle(IPriceOracle newOracle) onlyOwner() external {
    _oracle = newOracle;
  }

  function oracle() external view returns (address) {
    return address(_oracle);
  }  

  function setStrategy(IStrategy newStrategy) onlyOwner() external {
    _strategy = newStrategy;
    emit StrategyUpdated(newStrategy);
  }

  function strategy() external view returns (address) {
    return address(_strategy);
  }

  function asset() public view returns (IERC20) {
    return _strategy.asset();
  }

  function underlyingUnit() public view returns (uint256) {
    return _strategy.underlyingUnit();
  }

  function deposit(uint256 amount) public returns (uint256) {
    IERC20 _asset = asset();

    // if asset is ERC777, transferFrom can call reenter BEFORE the transfer happens through
    // the tokensToSend hook, so we need to transfer before we mint to keep the invariants.
    SafeERC20.safeTransferFrom(_asset, msg.sender, address(_strategy), amount);

    uint256 mintAmount = (amount * underlyingUnit()) / exchangeRate();
    _mint(msg.sender, mintAmount);

    _strategy.invest();

    emit Deposit(msg.sender, amount, mintAmount);
    return mintAmount;
  }

  function withdraw(uint256 lpAmount) public {
    uint256 curveLpAmount = (lpAmount * exchangeRate()) / underlyingUnit();

    // if _asset is ERC777, transfer can call reenter AFTER the transfer happens through
    // the tokensReceived hook, so we need to transfer after we burn to keep the invariants.
    _burn(msg.sender, lpAmount);

    _strategy.withdrawInvestment(curveLpAmount, msg.sender);

    emit Withdraw(msg.sender, curveLpAmount, lpAmount);
  }

  /** claims the accumulated CRV rewards from Curve and converts them to DAI */
  function harvest() external {
    IERC20 _asset = asset();
    uint256 initialBalance = assetBalance();

    _strategy.claim();
    convertCRVToAsset(_asset);

    uint256 newBalanceAfterRewards = assetBalance();
    assert(newBalanceAfterRewards > initialBalance);

    SafeERC20.safeTransfer(_asset, address(_strategy), assetBalance());
    emit Claim(newBalanceAfterRewards - initialBalance);
    _strategy.invest();
  }

  function convertCRVToAsset(IERC20 _asset) internal {
    IERC20 crvToken = _strategy.CRV();
    uint256 crvAmount = crvToken.balanceOf(address(this));

    address[] memory path = new address[](2);
    path[0] = address(crvToken);
    path[1] = address(_asset);

    uint256 crvPrice = _oracle.getPrice(address(crvToken));
    uint256 assetPrice = _oracle.getPrice(address(_asset));

    uint256 minimumAmount = (crvPrice * crvAmount) / assetPrice;
    uint256 minimumAmountAfterSlippage = (minimumAmount * SLIPPAGE) / 1000;

    SafeERC20.safeIncreaseAllowance(crvToken, address(_uniswapRouter), crvAmount);
    _uniswapRouter.swapExactTokensForTokens(
      crvAmount,
      minimumAmountAfterSlippage,
      path,
      address(this),
      block.timestamp
    );
  }

  function exchangeRate() public view returns (uint256) {
    return totalSupply() == 0
      ? underlyingUnit()
      : (underlyingUnit() * totalBalance()) / totalSupply();
  }

  function totalBalance() public view returns (uint256) {
    return assetBalance() + investedBalance();
  }

  /*
   * Asset balance across all users laying in this vault.
  */
  function assetBalance() public view returns (uint256) {
    return asset().balanceOf(address(this));
  }

  /*
   * Invested LP tokens balance across all users in this vault.
  */
  function investedBalance() public view returns (uint256) {
    return _strategy.investedBalance();
  }
}

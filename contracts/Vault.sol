// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/ICurve3Pool.sol";
import "./interfaces/ILiquidityGauge.sol";
import "./interfaces/ICurveFiMinter.sol";
import "./interfaces/IStrategy.sol";

contract Vault is ERC20, Ownable {
  using SafeERC20 for IERC20;
  using SafeMath for uint;
  IStrategy private _strategy;
  IUniswapV2Router02 private constant _uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  event Deposit(address _user, uint256 _underlying_amount, uint256 _shares);
  event Withdraw(address _user, uint256 _lp_amount, uint256 _shares);
  event Claim(uint256 rewards);

  constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

  function setStrategy(IStrategy newStrategy) onlyOwner() external {
    _strategy = newStrategy;
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

    uint256 mintAmount = amount.mul(underlyingUnit()).div(exchangeRate());
    _mint(msg.sender, mintAmount);

    _strategy.invest();

    emit Deposit(msg.sender, amount, mintAmount);
    return mintAmount;
  }

  function withdraw(uint256 lpAmount) public {
    uint256 curveLpAmount = lpAmount.mul(exchangeRate()).div(underlyingUnit());

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

    SafeERC20.safeTransfer(_asset, address(_strategy), assetBalance());

    emit Claim(newBalanceAfterRewards.sub(initialBalance));

    // Reinvest
    _strategy.invest();
  }

  function convertCRVToAsset(IERC20 _asset) internal {
    IERC20 crvToken = _strategy.CRV();
    uint256 crvAmount = crvToken.balanceOf(address(this));

    address[] memory path = new address[](2);
    path[0] = address(crvToken);
    path[1] = address(_asset);

    uint256 minAmount = _uniswapRouter.getAmountsOut(crvAmount, path)[1];

    SafeERC20.safeIncreaseAllowance(crvToken, address(_uniswapRouter), crvAmount);
    _uniswapRouter.swapExactTokensForTokens(
      crvAmount,
      minAmount,
      path,
      address(this),
      block.timestamp
    );
  }

  function exchangeRate() public view returns (uint256) {
    return totalSupply() == 0
      ? underlyingUnit()
      : underlyingUnit().mul(totalBalance()).div(totalSupply());
  }

  function totalBalance() public view returns (uint256) {
    return assetBalance().add(investedBalance());
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

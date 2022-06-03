// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ICurve3Pool.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/ICurveFiMinter.sol";
import "../interfaces/IStrategy.sol";

contract CurveStrategy {
  using SafeERC20 for IERC20;
  uint8 private immutable _ncoins;
  ERC20 public immutable _asset;
  ICurve3Pool private immutable _pool;
  ILiquidityGauge private immutable _gauge;
  address private immutable _vault;

  constructor(
    ERC20 underlying,
    ICurve3Pool pool,
    ILiquidityGauge gauge,
    address vault,
    uint8 ncoins
  ) {
    _asset = underlying;
    _pool = pool;
    _gauge = gauge;
    _vault = vault;
    _ncoins = ncoins;
  }

  modifier onlyVault() {
    require(_vault == msg.sender, "Strategy: caller is not the vault");
    _;
  }

  function CRV() external view returns (address) {
    return _gauge.crv_token();
  }

  function asset() external view returns (IERC20) {
    return _asset;
  }

  function underlyingUnit() external view returns (uint256) {
    return 10 ** _asset.decimals();
  }

  function invest() external {
    uint256 amount = _asset.balanceOf(address(this));

    SafeERC20.safeIncreaseAllowance(_asset, address(_pool), amount);
    _pool.add_liquidity([amount, 0, 0], 0);

    ERC20 lpToken = ERC20(_gauge.lp_token());
    uint256 lpTokens = lpToken.balanceOf(address(this));

    SafeERC20.safeIncreaseAllowance(lpToken, address(_gauge), lpTokens);
    _gauge.deposit(lpTokens);
  }

  function withdrawInvestment(uint256 amount, address to) onlyVault() external {
    _gauge.withdraw(amount);

    ERC20 lpToken = ERC20(_gauge.lp_token());
    uint256 lpTokens = lpToken.balanceOf(address(this));

    uint256[3] memory _amounts = calcTokenAmounts(lpTokens); 
    _pool.remove_liquidity(lpTokens, _amounts);

    for (uint8 i = 0; i < _ncoins; i++){
      ERC20 coin = ERC20(_pool.coins(i));
      SafeERC20.safeTransfer(coin, to, _amounts[i]);
    }
  }

  function calcTokenAmounts(uint256 lpAmount) internal view returns(uint256[3] memory amounts) {
    ERC20 lpToken = ERC20(_gauge.lp_token());
    uint256 totalSupply = lpToken.totalSupply();

    for (uint8 i = 0; i < _ncoins; i++){
      uint256 balance = _pool.balances(i);
      amounts[i] = (balance * lpAmount) / totalSupply;
    }
    return amounts;
  }

  /* claims the accumulated CRV rewards from Curve and send to vault*/
  function claim() external {
    ICurveFiMinter minter = ICurveFiMinter(_gauge.minter());
    minter.mint(address(_gauge));

    IERC20 crv = IERC20(_gauge.crv_token());
    SafeERC20.safeTransfer(crv, _vault, crv.balanceOf(address(this)));
  }

  /*
   * Invested LP tokens balance across all users in this Strategy.
  */
  function investedBalance() external view returns (uint256) {
    return _gauge.balanceOf(address(this));
  }
}

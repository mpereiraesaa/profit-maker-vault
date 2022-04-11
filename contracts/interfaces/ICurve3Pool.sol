// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

/** 
 * @dev Interface for Curve.Fi swap contract for 3pool.
 * @dev See original implementation in official repository:
 * https://github.com/curvefi/curve-contract/blob/master/contracts/pools/3pool/StableSwap3Pool.vy
 */
interface ICurve3Pool { 
  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;
  function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;
  function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount) external;
  function calc_token_amount(uint256[3] calldata amounts, bool deposit) external view returns(uint256);
  function balances(uint256 arg0) external view returns(uint256);
  function coins(uint256 arg0) external view returns (address);
}

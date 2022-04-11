// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

/** 
 * @dev Interface for Curve.Fi CRV minter contract.
 * @dev See original implementation in official repository:
 * https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/Minter.vy
 */
interface ICurveFiMinter {
  function mint(address gauge_addr) external;
  function minted(address _for, address gauge_addr) external view returns(uint256);
  function token() external view returns(address);
}

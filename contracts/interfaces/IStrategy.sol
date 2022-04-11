// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** 
 * @dev Interface for strategies used in Vault
 */
interface IStrategy {
  function underlyingUnit() external view returns (uint256);
  function investedBalance() external view returns (uint256);
  function asset() external view returns (IERC20);
  function CRV() external view returns (IERC20);
  function withdrawInvestment(uint256 amount, address to) external;
  function invest() external;
  function claim() external;
}

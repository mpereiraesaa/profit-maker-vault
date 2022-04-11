// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface ILiquidityGauge {
  function deposit(uint256 _value) external;
  function withdraw(uint256 _value) external;
  function lp_token() external view returns (address);
  function crv_token() external view returns (address);
  function minter() external view returns (address);
  function balanceOf(address arg0) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// 3pool gauge: 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A

interface LiquidityGauge {
  function deposit(uint256 _value) external;
  function withdraw(uint256 _value) external;
}

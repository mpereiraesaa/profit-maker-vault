// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// 3pool: 0xA79828DF1850E8a3A3064576f380D90aECDD3359

interface DepositZap {
  function add_liquidity(
    address _pool,
    uint256[4] _deposit_amounts,
    uint256 _min_mint_amount
  ) external returns (uint256);
  function remove_liquidity(
    address _pool,
    uint256 _burn_amount,
    uint256[4] _min_amounts
  ) external returns (uint256[4]);
}

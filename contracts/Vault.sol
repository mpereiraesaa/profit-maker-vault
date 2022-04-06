// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Vault is ERC20 {
  using SafeERC20 for IERC20;
  ERC20 public immutable _asset;

  event Deposit(address _user, uint256 _underlying_amount, uint256 _shares);
  event Withdraw(address _user, uint256 _underlying_amount, uint256 _shares);

  constructor(
    ERC20 asset,
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) {
    _asset = asset;
  }

  /**
   * @dev See {IERC4626-convertToShares}
  */
  function convertToShares(uint256 assets) public view returns (uint256) {
    uint256 supply = totalSupply();

    return (assets == 0 || supply == 0) ? (assets * 10**decimals()) / 10**_asset.decimals() : (assets * supply) / totalAssets();
  }

  /** @dev See {IERC4626-convertToAssets} */
  function convertToAssets(uint256 shares) public view returns (uint256 assets) {
    uint256 supply = totalSupply();

    return (supply == 0) ? (shares * 10**_asset.decimals()) / 10**decimals() : (shares * totalAssets()) / supply;
  }

  /** @dev See {IERC4626-deposit} */
  function deposit(uint256 underlyingAmount) public returns (uint256) {
    address caller = _msgSender();
    uint256 shares = convertToShares(underlyingAmount);

    // if _asset is ERC777, transferFrom can call reenter BEFORE the transfer happens through
    // the tokensToSend hook, so we need to transfer before we mint to keep the invariants.
    SafeERC20.safeTransferFrom(_asset, caller, address(this), underlyingAmount);
    _mint(caller, shares);

    emit Deposit(caller, underlyingAmount, shares);

    return shares;
  }

  /** @dev See {IERC4626-withdraw} */
  function withdraw(
    uint256 lpAmount
  ) public {
    address caller = _msgSender();
    uint256 underlyingAmount = convertToAssets(lpAmount);

    // if _asset is ERC777, transfer can call reenter AFTER the transfer happens through
    // the tokensReceived hook, so we need to transfer after we burn to keep the invariants.
    _burn(caller, lpAmount);
    SafeERC20.safeTransfer(_asset, caller, underlyingAmount);

    emit Withdraw(caller, underlyingAmount, lpAmount);
  }

  function harvest() external {}

  function exchangeRate() external view {}

  /** @dev See {IERC4626-totalAssets} */
  function totalAssets() public view returns (uint256) {
    return _asset.balanceOf(address(this));
  }
}

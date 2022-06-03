// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

/** 
 * @dev Interface for Oracle used in Vault
 */
interface IPriceOracle {
    function getPrice(address tokenAddress) external view returns (uint256 price);
    function setFeed(string calldata symbol, address feed) external;
}

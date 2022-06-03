// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/chainlink/IAggregator.sol";

contract PriceOracle is Ownable {
    mapping(bytes32 => IAggregator) internal feeds;

    event FeedSet(address feed, string symbol);

    function getPrice(address tokenAddress) external view returns (uint256 price) {
      IERC20Metadata token = IERC20Metadata(tokenAddress);

      price = getChainlinkPrice(getFeed(token.symbol()));

      uint256 decimalDelta = 18 - token.decimals();
      // Ensure that we don't multiply the result by 0
      if (decimalDelta > 0) {
        return price * (10**decimalDelta);
      } else {
        return price;
      }
    }

    function getChainlinkPrice(IAggregator feed) internal view returns (uint256) {
        // Chainlink USD-denominated feeds store answers at 8 decimals
        uint256 decimalDelta = 18 - feed.decimals();
        // Ensure that we don't multiply the result by 0
        if (decimalDelta > 0) {
            return uint256(feed.latestAnswer()) * (10**decimalDelta);
        } else {
            return uint256(feed.latestAnswer());
        }
    }

    function getFeed(string memory symbol) public view returns (IAggregator) {
        return feeds[keccak256(abi.encodePacked(symbol))];
    }

    function setFeed(string calldata symbol, address feed) external onlyOwner() {
        require(feed != address(0) && feed != address(this), "invalid feed address");
        emit FeedSet(feed, symbol);
        feeds[keccak256(abi.encodePacked(symbol))] = IAggregator(feed);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeedRegistry } from "../../src/interfaces/IEOFeedRegistry.sol";

contract MockEOFeedRegistry is IEOFeedRegistry {
    mapping(string => PriceFeed) public priceFeeds;

    function updatePriceFeed(string calldata symbol, uint256 value, uint256 timestamp, bytes memory) external {
        priceFeeds[symbol] = PriceFeed(value, timestamp);
    }

    function updatePriceFeeds(
        string[] calldata symbols,
        uint256[] calldata values,
        uint256[] calldata timestamps,
        bytes[] memory
    )
        external
    {
        for (uint256 i = 0; i < symbols.length; i++) {
            priceFeeds[symbols[i]] = PriceFeed(values[i], timestamps[i]);
        }
    }

    function getLatestPriceFeed(string calldata symbol) external view returns (PriceFeed memory) {
        return priceFeeds[symbol];
    }

    function getLatestPriceFeeds(string[] calldata symbols) external view returns (PriceFeed[] memory) {
        PriceFeed[] memory feeds = new PriceFeed[](symbols.length);
        for (uint256 i = 0; i < symbols.length; i++) {
            feeds[i] = priceFeeds[symbols[i]];
        }
        return feeds;
    }
}

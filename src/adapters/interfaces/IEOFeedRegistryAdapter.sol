// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeed } from "./IEOFeed.sol";

/**
 * @title IEOFeedRegistryAdapter
 * @notice Interface for the FeedRegistry contract.
 * @dev Simplified version of IEOFeedRegistryAdapter from Chainlink.
 */
interface IEOFeedRegistryAdapter {
    function decimals(address base, address quote) external view returns (uint8);

    function description(address base, address quote) external view returns (string memory);

    function version(address base, address quote) external view returns (uint256);

    function latestAnswer(address base, address quote) external view returns (int256 answer);

    function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

    function getFeed(address base, address quote) external view returns (IEOFeed feed);

    function isFeedEnabled(address feed) external view returns (bool);

    function getRoundFeed(address base, address quote, uint80 roundId) external view returns (IEOFeed feed);
}

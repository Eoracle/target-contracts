// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeed } from "./IEOFeed.sol";

/**
 * @title IEOFeedRegistryAdapter
 * @notice Interface for the FeedRegistry contract.
 * @dev Simplified version of FeedRegistryInterface from CL.
 */
interface IEOFeedRegistryAdapter {
    // V3 AggregatorV3Interface

    function decimals(address base, address quote) external view returns (uint8);

    function description(address base, address quote) external view returns (string memory);

    function version(address base, address quote) external view returns (uint256);

    function latestRoundData(
        address base,
        address quote
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function getRoundData(
        address base,
        address quote,
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    // V2 AggregatorInterface

    function latestAnswer(address base, address quote) external view returns (int256 answer);

    function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

    function latestRound(address base, address quote) external view returns (uint256 roundId);

    function getAnswer(address base, address quote, uint256 roundId) external view returns (int256 answer);

    function getTimestamp(address base, address quote, uint256 roundId) external view returns (uint256 timestamp);

    // Registry getters

    function getFeed(address base, address quote) external view returns (IEOFeed feed);

    function isFeedEnabled(address feed) external view returns (bool);

    function getRoundFeed(address base, address quote, uint80 roundId) external view returns (IEOFeed feed);
}

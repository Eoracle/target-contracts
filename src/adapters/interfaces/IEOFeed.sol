// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeedRegistry } from "../../interfaces/IEOFeedRegistry.sol";

/**
 * @title IEOFeed
 * @notice Interface for the EOFeed contract.
 * @dev compatible of AggregatorV3Interface from CL.
 */
interface IEOFeed {
    function initialize(
        IEOFeedRegistry feedRegistry,
        uint16 pairSymbol,
        uint8 decimals,
        string memory description,
        uint256 version
    )
        external;
    function getPairSymbol() external view returns (uint16);
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

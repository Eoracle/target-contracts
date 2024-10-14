// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedVerifier } from "./IEOFeedVerifier.sol";

interface IEOFeedManager {
    /**
     * @dev Price feed structure
     * @param value Price feed value
     * @param timestamp Price feed timestamp (block timestamp in eoracle chain when price feed rate is aggregated)
     * @param eoracleBlockNumber eoracle block number
     */
    struct PriceFeed {
        uint256 value;
        uint256 timestamp;
        uint256 eoracleBlockNumber;
    }

    /**
     * @dev Event emitted when a price feed is updated
     * @param feedId Feed id
     * @param rate Price feed value
     * @param timestamp Price feed timestamp
     */
    event RateUpdated(uint16 indexed feedId, uint256 rate, uint256 timestamp);

    /**
     * @notice Update the price for a feed
     * @param input A merkle leaf containing price data and its merkle proof
     * @param vParams Verification parameters
     */
    function updatePriceFeed(
        IEOFeedVerifier.LeafInput calldata input,
        IEOFeedVerifier.VerificationParams calldata vParams
    )
        external;

    /**
     * @notice Update the price for multiple feeds
     * @param inputs Array of leafs to prove the price feeds
     * @param vParams Verification parameters
     */
    function updatePriceFeeds(
        IEOFeedVerifier.LeafInput[] calldata inputs,
        IEOFeedVerifier.VerificationParams calldata vParams
    )
        external;

    /**
     * @notice Set the whitelisted publishers
     * @param publishers Array of publisher addresses
     * @param isWhitelisted Array of booleans indicating whether the publisher is whitelisted
     */
    function whitelistPublishers(address[] memory publishers, bool[] memory isWhitelisted) external;

    /**
     * @notice Get the latest price for a feed
     * @param feedId Feed id
     * @return PriceFeed struct
     */
    function getLatestPriceFeed(uint16 feedId) external view returns (PriceFeed memory);

    /**
     * @notice Get the latest price feeds for multiple feeds
     * @param feedIds Array of feed ids
     * @return Array of PriceFeed structs
     */
    function getLatestPriceFeeds(uint16[] calldata feedIds) external view returns (PriceFeed[] memory);

    /**
     * @notice Check if a publisher is whitelisted
     * @param publisher Address of the publisher
     * @return Boolean indicating whether the publisher is whitelisted
     */
    function isWhitelistedPublisher(address publisher) external view returns (bool);

    /**
     * @notice Check if a feed is supported
     * @param feedId feed Id to check
     * @return Boolean indicating whether the feed is supported
     */
    function isSupportedFeed(uint16 feedId) external view returns (bool);
}

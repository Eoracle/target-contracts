// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeedVerifier } from "./IEOFeedVerifier.sol";

interface IEOFeedRegistry {
    struct PriceFeed {
        uint256 value;
        uint256 timestamp;
    }

    function updatePriceFeed(IEOFeedVerifier.LeafInput memory input, bytes calldata checkpointData) external;

    function updatePriceFeeds(IEOFeedVerifier.LeafInput[] calldata inputs, bytes calldata checkpointData) external;

    function whitelistPublishers(address[] memory publishers, bool[] memory isWhitelisted) external;

    function getLatestPriceFeed(uint16 symbol) external view returns (PriceFeed memory);
    function getLatestPriceFeeds(uint16[] calldata symbols) external view returns (PriceFeed[] memory);

    function isWhitelistedPublisher(address publisher) external view returns (bool);
    function isSupportedSymbol(uint16 symbol) external view returns (bool);
}

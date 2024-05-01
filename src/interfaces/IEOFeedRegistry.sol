// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeedVerifier } from "./IEOFeedVerifier.sol";

interface IEOFeedRegistry {
    struct PriceFeed {
        uint256 value;
        uint256 timestamp;
    }

    function updatePriceFeed(bytes calldata proofData) external;

    function updatePriceFeeds(
        IEOFeedVerifier.BatchExitInput[] calldata proofDatas,
        bytes calldata checkpointData
    )
        external;

    function getLatestPriceFeed(uint16 symbol) external view returns (PriceFeed memory);
    function getLatestPriceFeeds(uint16[] calldata symbols) external view returns (PriceFeed[] memory);
}

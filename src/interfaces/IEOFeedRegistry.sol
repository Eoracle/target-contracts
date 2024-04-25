// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IEOFeedRegistry {
    struct PriceFeed {
        uint256 value;
        uint256 timestamp;
    }

    function updatePriceFeed(
        string calldata symbol,
        uint256 value,
        uint256 timestamp,
        bytes memory proofData
    )
        external;

    function updatePriceFeeds(
        string[] calldata symbols,
        uint256[] calldata values,
        uint256[] calldata timestamps,
        bytes[] memory proofDatas
    )
        external;

    function getLatestPriceFeed(string calldata symbol) external view returns (PriceFeed memory);
    function getLatestPriceFeeds(string[] calldata symbols) external view returns (PriceFeed[] memory);
}

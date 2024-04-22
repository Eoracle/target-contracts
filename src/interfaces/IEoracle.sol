// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IEoracle {
    struct PriceFeed {
        uint256 value;
        uint256 timestamp;
    }

    function updatePriceFeed(
        string calldata symbols,
        uint256 value,
        uint256 timestamp,
        bytes memory proofData
    ) external;

    function updatePriceFeeds(
        string[] calldata symbols,
        uint256[] calldata values,
        uint256[] calldata timestamps,
        bytes[] memory proofDatas
    ) external;

    function getLatestPriceFeed(string calldata symbols) external view returns (PriceFeed memory);
    function getLatestPriceFeeds(string[] calldata symbols) external view returns (PriceFeed[] memory);
}

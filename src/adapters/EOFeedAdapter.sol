// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedManager } from "../interfaces/IEOFeedManager.sol";
import { IEOFeedAdapter } from "./interfaces/IEOFeedAdapter.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { InvalidAddress } from "../interfaces/Errors.sol";

/**
 * @title EOFeedAdapter
 * @notice Price feed adapter contract
 */
contract EOFeedAdapter is IEOFeedAdapter, Initializable {
    /// @dev Feed manager contract
    IEOFeedManager private _feedManager;

    /// @dev Feed version
    uint256 private _version;

    /// @dev Feed description
    string private _description;

    // next 2 variables will be packed in 1 slot
    /// @dev Feed id
    uint16 private _feedId;

    /// @dev Decimals of the rate
    uint8 private _decimals;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract
     * @param feedManager The feed manager address
     * @param feedId Feed id
     * @param feedDecimals The decimals of the rate
     * @param feedDescription The description of feed
     * @param feedVersion The version of feed
     */
    function initialize(
        address feedManager,
        uint16 feedId,
        uint8 feedDecimals,
        string memory feedDescription,
        uint256 feedVersion
    )
        external
        initializer
    {
        if (feedManager == address(0)) revert InvalidAddress();
        _feedManager = IEOFeedManager(feedManager);
        _feedId = feedId;
        _decimals = feedDecimals;
        _description = feedDescription;
        _version = feedVersion;
    }

    /**
     * @notice Get the price for the round
     * @param
     * @return roundId The round id
     * @return answer The price
     * @return startedAt The timestamp of the start of the round
     * @return updatedAt The timestamp of the end of the round
     * @return answeredInRound The round id in which the answer was computed
     */
    function getRoundData(uint80) external view returns (uint80, int256, uint256, uint256, uint80) {
        IEOFeedManager.PriceFeed memory priceData = _feedManager.getLatestPriceFeed(_feedId);
        return (
            uint80(priceData.eoracleBlockNumber),
            int256(priceData.value),
            priceData.timestamp,
            priceData.timestamp,
            uint80(priceData.eoracleBlockNumber)
        );
    }

    /**
     * @notice Get the latest price
     * @return roundId The round id
     * @return answer The price
     * @return startedAt The timestamp of the start of the round
     * @return updatedAt The timestamp of the end of the round
     * @return answeredInRound The round id in which the answer was computed
     */
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80) {
        IEOFeedManager.PriceFeed memory priceData = _feedManager.getLatestPriceFeed(_feedId);
        return (
            uint80(priceData.eoracleBlockNumber),
            int256(priceData.value),
            priceData.timestamp,
            priceData.timestamp,
            uint80(priceData.eoracleBlockNumber)
        );
    }

    /**
     * @notice Get the latest price
     * @return int256 The price
     */
    function latestAnswer() external view returns (int256) {
        IEOFeedManager.PriceFeed memory priceData = _feedManager.getLatestPriceFeed(_feedId);
        return int256(priceData.value);
    }

    /**
     * @notice Get the latest timestamp
     * @return uint256 The timestamp
     */
    function latestTimestamp() external view returns (uint256) {
        IEOFeedManager.PriceFeed memory priceData = _feedManager.getLatestPriceFeed(_feedId);
        return priceData.timestamp;
    }

    /**
     * @notice Get the price for the round (round is not used, the latest price is returned)
     * @param
     * @return int256 The price
     */
    function getAnswer(uint256) external view returns (int256) {
        IEOFeedManager.PriceFeed memory priceData = _feedManager.getLatestPriceFeed(_feedId);
        return int256(priceData.value);
    }

    /**
     * @notice Get the timestamp for the round (round is not used, the latest timestamp is returned)
     * @param
     * @return uint256 The timestamp
     */
    function getTimestamp(uint256) external view returns (uint256) {
        IEOFeedManager.PriceFeed memory priceData = _feedManager.getLatestPriceFeed(_feedId);
        return priceData.timestamp;
    }

    /**
     * @notice Get the id of the feed
     * @return uint16 The feed id
     */
    function getFeedId() external view returns (uint16) {
        return _feedId;
    }

    /**
     * @notice Get the decimals of the rate
     * @return uint8 The decimals
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Get the description of the feed
     * @return string The description
     */
    function description() external view returns (string memory) {
        return _description;
    }

    /**
     * @notice Get the version of the feed
     * @return uint256 The version
     */
    function version() external view returns (uint256) {
        return _version;
    }

    /**
     * @notice Get the latest round
     * @return uint256 The round id, eoracle block number
     */
    function latestRound() external view returns (uint256) {
        IEOFeedManager.PriceFeed memory priceData = _feedManager.getLatestPriceFeed(_feedId);
        return priceData.eoracleBlockNumber;
    }

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

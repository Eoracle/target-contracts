// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedRegistry } from "../interfaces/IEOFeedRegistry.sol";
import { IEOFeed } from "./interfaces/IEOFeed.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title EOFeed
 * @notice The contract for the symbol pair price feed
 */
contract EOFeed is IEOFeed, Initializable {
    IEOFeedRegistry private _feedRegistry;

    uint256 private _version;
    string private _description;
    // next 2 variables will be packed in 1 slot
    uint16 private _pairSymbol; // should coincide with the symbols pair identifier in the feed registry
    uint8 private _decimals;

    /**
     * @notice Initialize the contract
     * @param feedRegistry The feed registry address
     * @param pairSymbol Pair Symbol
     * @param rateDecimals The decimals of the rate
     * @param pairDescription The description of symbols pair
     * @param feedVersion The version of feed
     */
    function initialize(
        IEOFeedRegistry feedRegistry,
        uint16 pairSymbol,
        uint8 rateDecimals,
        string memory pairDescription,
        uint256 feedVersion
    )
        public
        initializer
    {
        _feedRegistry = feedRegistry;
        _pairSymbol = pairSymbol;
        _decimals = rateDecimals;
        _description = pairDescription;
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
        IEOFeedRegistry.PriceFeed memory priceData = _feedRegistry.getLatestPriceFeed(_pairSymbol);
        return (0, int256(priceData.value), priceData.timestamp, priceData.timestamp, 0);
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
        IEOFeedRegistry.PriceFeed memory priceData = _feedRegistry.getLatestPriceFeed(_pairSymbol);
        return (0, int256(priceData.value), priceData.timestamp, priceData.timestamp, 0);
    }

    /**
     * @notice Get the latest price
     * @return int256 The price
     */
    function latestAnswer() external view returns (int256) {
        IEOFeedRegistry.PriceFeed memory priceData = _feedRegistry.getLatestPriceFeed(_pairSymbol);
        return int256(priceData.value);
    }

    /**
     * @notice Get the latest timestamp
     * @return uint256 The timestamp
     */
    function latestTimestamp() external view returns (uint256) {
        IEOFeedRegistry.PriceFeed memory priceData = _feedRegistry.getLatestPriceFeed(_pairSymbol);
        return priceData.timestamp;
    }

    /**
     * @notice Get the price for the round (round is not used, the lasest price is returned)
     * @param
     * @return int256 The price
     */
    function getAnswer(uint256) external view returns (int256) {
        IEOFeedRegistry.PriceFeed memory priceData = _feedRegistry.getLatestPriceFeed(_pairSymbol);
        return int256(priceData.value);
    }

    /**
     * @notice Get the timestamp for the round (round is not used, the lasest timestamp is returned)
     * @param
     * @return uint256 The timestamp
     */
    function getTimestamp(uint256) external view returns (uint256) {
        IEOFeedRegistry.PriceFeed memory priceData = _feedRegistry.getLatestPriceFeed(_pairSymbol);
        return priceData.timestamp;
    }

    /**
     * @notice Get the pair symbol
     * @return string The pair symbol
     */
    function getPairSymbol() external view returns (uint16) {
        return _pairSymbol;
    }

    /**
     * @notice Get the decimals of the rate
     * @return uint8 The decimals
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Get the description of the feed symbol pairs
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
     * @return uint256 The round, round is not used, 0 is returned
     */
    function latestRound() external pure returns (uint256) {
        return 0;
    }
}

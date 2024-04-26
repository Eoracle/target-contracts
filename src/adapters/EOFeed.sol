// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeedRegistry } from "../interfaces/IEOFeedRegistry.sol";
import { IEOFeed } from "./interfaces/IEOFeed.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract EOFeed is IEOFeed, Initializable {
    uint8 private _decimals;
    string private _description; // should coincide with the symbols pair identifier in the feed registry
    uint256 private _version;

    IEOFeedRegistry private _feedRegistry;

    /**
     * @notice Initialize the contract
     * @param feedRegistry The feed registry address
     * @param decimals_ The decimals of the reate
     * @param description_ The description of symbols pair
     * @param version_ The version of feed
     */
    function initialize(
        address feedRegistry,
        uint8 decimals_,
        string memory description_,
        uint256 version_
    )
        public
        initializer
    {
        _feedRegistry = IEOFeedRegistry(feedRegistry);
        _decimals = decimals_;
        _description = description_;
        _version = version_;
    }

    /**
     * @notice Get the price for the round
     * @param _roundId The round id
     * @return roundId The round id
     * @return answer The price
     * @return startedAt The timestamp of the start of the round
     * @return updatedAt The timestamp of the end of the round
     * @return answeredInRound The round id in which the answer was computed
     */
    function getRoundData(uint80 _roundId) public view override returns (uint80, int256, uint256, uint256, uint80) {
        IEOFeedRegistry.PriceFeed memory priceData = _feedRegistry.getLatestPriceFeed(_description);
        return (_roundId, int256(priceData.value), 0, priceData.timestamp, _roundId);
    }

    /**
     * @notice Get the latest price
     * @return roundId The round id
     * @return answer The price
     * @return startedAt The timestamp of the start of the round
     * @return updatedAt The timestamp of the end of the round
     * @return answeredInRound The round id in which the answer was computed
     */
    function latestRoundData() public view override returns (uint80, int256, uint256, uint256, uint80) {
        IEOFeedRegistry.PriceFeed memory priceData = _feedRegistry.getLatestPriceFeed(_description);
        return (0, int256(priceData.value), 0, priceData.timestamp, 0);
    }

    /**
     * @notice Get the decimals of the rate
     * @return uint8 The decimals
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Get the description of the feed symbol pairs
     * @return string The description
     */
    function description() public view override returns (string memory) {
        return _description;
    }

    /**
     * @notice Get the version of the feed
     * @return uint256 The version
     */
    function version() public view override returns (uint256) {
        return _version;
    }
}

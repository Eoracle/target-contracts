// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { IEOFeedRegistry } from "../interfaces/IEOFeedRegistry.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IEOFeed } from "./interfaces/IEOFeed.sol";
import { FeedRegistryInterface } from "./interfaces/FeedRegistryInterface.sol";
import { EOFeedFactoryBeacon } from "./factories/EOFeedFactoryBeacon.sol";

contract EOFeedRegistryAdapter is OwnableUpgradeable, EOFeedFactoryBeacon, FeedRegistryInterface {
    IEOFeedRegistry internal _feedRegistry;
    mapping(string => IEOFeed) internal _pairSymbolsToFeeds;
    mapping(address => bool) internal _feedEnabled;
    mapping(address => mapping(address => string)) internal _tokenAddressesToPairSymbols;

    event FeedCloned(string pairSymbol, IEOFeed feed);
    event PairSymbolAdded(address base, address quote, string pairSymbol);

    error FeedAlreadyExists(address feed);
    error BaseQuotePairExists();

    /**
     * @notice Initialize the contract
     * @param feedRegistry The feed registry address
     */
    function initialize(IEOFeedRegistry feedRegistry, address feedImplementation) external initializer {
        __Ownable_init(msg.sender);
        __EOFeedFactory_init(feedImplementation, msg.sender);
        _feedRegistry = feedRegistry;
    }

    /**
     * @notice deploy EOFeed
     * @param base The base asset address
     * @param quote The quote asset address
     * @param pairSymbol The pair symbol
     * @param decimals_ The decimals
     * @param version_ The version
     */
    function deployEOFeed(
        address base,
        address quote,
        string calldata pairSymbol,
        uint8 decimals_,
        uint256 version_
    )
        external
        onlyOwner
    {
        address feedAddress = address(_pairSymbolsToFeeds[pairSymbol]);
        if (feedAddress != address(0)) {
            revert FeedAlreadyExists(feedAddress);
        }
        if (bytes(_tokenAddressesToPairSymbols[base][quote]).length != 0) {
            revert BaseQuotePairExists();
        }
        address feed = _deployEOFeed();
        IEOFeed(feed).initialize(address(_feedRegistry), decimals_, pairSymbol, version_);

        _feedEnabled[feed] = true;

        _pairSymbolsToFeeds[pairSymbol] = IEOFeed(feed);
        emit FeedCloned(pairSymbol, IEOFeed(feed));

        _tokenAddressesToPairSymbols[base][quote] = pairSymbol;
        emit PairSymbolAdded(base, quote, pairSymbol);
    }

    /**
     * @notice Get the feed for a given pair symbol
     * @param symbol The pair symbol
     * @return IEOFeed The feed
     */
    function getFeedByPairSymbol(string calldata symbol) external view returns (IEOFeed) {
        return _pairSymbolsToFeeds[symbol];
    }

    // implement FeedRegistryInterface
    /**
     * @notice Get the latest price for a given base/quote pair
     * @dev Calls the getLatestPriceFeed function from the feed registry, not from Feed itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return int256 The latest price
     */
    function latestAnswer(address base, address quote) external view override returns (int256) {
        return int256(_feedRegistry.getLatestPriceFeed(_tokenAddressesToPairSymbols[base][quote]).value);
    }

    /**
     * @notice Get the latest timestamp for a given base/quote pair
     * @dev Calls the getLatestPriceFeed function from the feed registry, not from Feed itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return uint256 The latest timestamp
     */
    function latestTimestamp(address base, address quote) external view returns (uint256) {
        return _feedRegistry.getLatestPriceFeed(_tokenAddressesToPairSymbols[base][quote]).timestamp;
    }

    /**
     * @notice Get the feed for a given base/quote pair
     * @param base The base asset address
     * @param quote The quote asset address
     * @return IEOFeed The feed
     */
    function getFeed(address base, address quote) external view override returns (IEOFeed) {
        return _getFeed(base, quote);
    }

    /**
     * @notice Get the decimals for a given base/quote pair
     * @dev Calls the decimals function from the feed itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return uint8 The decimals
     */
    function decimals(address base, address quote) external view returns (uint8) {
        return _pairSymbolsToFeeds[_tokenAddressesToPairSymbols[base][quote]].decimals();
    }

    /**
     * @notice Get the description for a given base/quote pair
     * @dev Calls the description function from the feed itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return string The description
     */
    function description(address base, address quote) external view returns (string memory) {
        return _pairSymbolsToFeeds[_tokenAddressesToPairSymbols[base][quote]].description();
    }

    /**
     * @notice Get the version for a given base/quote pair
     * @dev Calls the version function from the feed itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return uint256 The version
     */
    function version(address base, address quote) external view returns (uint256) {
        return _pairSymbolsToFeeds[_tokenAddressesToPairSymbols[base][quote]].version();
    }

    /**
     * @notice Check if a feed is enabled in the storage of adapter
     * @param feed The feed address
     * @return bool True if the feed is enabled
     */
    function isFeedEnabled(address feed) external view returns (bool) {
        return _feedEnabled[feed];
    }

    /**
     * @notice Get the round feed for a given base/quote pair
     * @param base The base asset address
     * @param quote The quote asset address
     * @param
     * @return IEOFeed The feed
     */
    function getRoundFeed(address base, address quote, uint80) external view returns (IEOFeed) {
        return _getFeed(base, quote);
    }

    /**
     * @notice Get the feed for a given base/quote pair
     * @param base The base asset address
     * @param quote The quote asset address
     * @return IEOFeed The feed
     */
    function _getFeed(address base, address quote) internal view returns (IEOFeed) {
        return _pairSymbolsToFeeds[_tokenAddressesToPairSymbols[base][quote]];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedRegistry } from "../interfaces/IEOFeedRegistry.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IEOFeed } from "./interfaces/IEOFeed.sol";
import { IEOFeedRegistryAdapter } from "./interfaces/IEOFeedRegistryAdapter.sol";
import { EOFeedFactoryBase } from "./factories/EOFeedFactoryBase.sol";

/**
 * @title EOFeedRegistryAdapterBase
 * @notice base contract which is adapter of EOFeedRegistry contract for CL FeedRegistry
 */
abstract contract EOFeedRegistryAdapterBase is OwnableUpgradeable, EOFeedFactoryBase, IEOFeedRegistryAdapter {
    IEOFeedRegistry internal _feedRegistry;
    mapping(uint16 => IEOFeed) internal _pairSymbolsToFeeds;
    mapping(address => bool) internal _feedEnabled;
    mapping(address => mapping(address => uint16)) internal _tokenAddressesToPairSymbols;

    event FeedRegistrySet(address indexed feedRegistry);
    event FeedDeployed(uint16 indexed pairSymbol, address indexed feed);
    event PairSymbolAdded(address indexed base, address indexed quote, uint16 indexed pairSymbol);

    error FeedAlreadyExists();
    error BaseQuotePairExists();
    error SymbolNotSupported();

    /**
     * @notice Initialize the contract
     * @param feedRegistry The feed registry address
     * @param feedImplementation The feed implementation address
     * @param owner Owner of the contract
     */
    function initialize(address feedRegistry, address feedImplementation, address owner) external initializer {
        __Ownable_init(owner);
        __EOFeedFactory_init(feedImplementation, owner);
        _feedRegistry = IEOFeedRegistry(feedRegistry);
        emit FeedRegistrySet(feedRegistry);
    }

    /**
     * @notice Set the feed registry
     * @param feedRegistry The feed registry address
     */
    function setFeedRegistry(address feedRegistry) external onlyOwner {
        _feedRegistry = IEOFeedRegistry(feedRegistry);
        emit FeedRegistrySet(feedRegistry);
    }

    /**
     * @notice deploy EOFeed
     * @param base The base asset address
     * @param quote The quote asset address
     * @param pairSymbol The pair symbol
     * @param decimals_ The decimals
     * @param version_ The version
     * @return IEOFeed The feed
     */
    function deployEOFeed(
        address base,
        address quote,
        uint16 pairSymbol,
        string calldata description_,
        uint8 decimals_, // 18
        uint256 version_ // 1
    )
        external
        onlyOwner
        returns (IEOFeed)
    {
        // check if pairSymbol exists in feedRegistry contract
        if (!_feedRegistry.isSupportedSymbol(pairSymbol)) {
            revert SymbolNotSupported();
        }

        if (address(_pairSymbolsToFeeds[pairSymbol]) != address(0)) {
            revert FeedAlreadyExists();
        }
        if (_tokenAddressesToPairSymbols[base][quote] != 0) {
            revert BaseQuotePairExists();
        }
        address feed = _deployEOFeed();
        IEOFeed(feed).initialize(_feedRegistry, pairSymbol, decimals_, description_, version_);

        _feedEnabled[feed] = true;

        _pairSymbolsToFeeds[pairSymbol] = IEOFeed(feed);
        emit FeedDeployed(pairSymbol, feed);

        _tokenAddressesToPairSymbols[base][quote] = pairSymbol;
        emit PairSymbolAdded(base, quote, pairSymbol);

        return IEOFeed(feed);
    }

    /**
     * @notice Get the feed registry
     * @return IEOFeedRegistry The feed registry
     */
    function getFeedRegistry() external view returns (IEOFeedRegistry) {
        return _feedRegistry;
    }

    /**
     * @notice Get the feed for a given pair symbol
     * @param symbol The pair symbol
     * @return IEOFeed The feed
     */
    function getFeedByPairSymbol(uint16 symbol) external view returns (IEOFeed) {
        return _pairSymbolsToFeeds[symbol];
    }

    // implement IEOFeedRegistryAdapter
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

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

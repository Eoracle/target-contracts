// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";
import { IEOFeedRegistry } from "./interfaces/IEOFeedRegistry.sol";

contract EOFeedRegistry is Initializable, OwnableUpgradeable, IEOFeedRegistry {
    //  TODO: for chainlink compatibility should have such mapping
    //      mapping(address => mapping(address => mapping(uint16 => IEOFeed)));
    mapping(string => PriceFeed) internal _priceFeeds;
    mapping(address => bool) internal _whitelistedPublishers;
    // TODO: is it symbol or pair of symbols? "btc" or "btc/usd"
    mapping(string => bool) internal _supportedSymbols;
    // TODO: supportedFeeds mapping(address => bool) internal _supportedFeeds; ?

    // TODO: no setter for the _feedVerifier, is it intended?
    IEOFeedVerifier internal _feedVerifier;

    // This is for debugging
    // event DebugLatency(
    //     uint256 originalTimestamp,
    //     uint256 currentTimestamp,
    //     uint256 latency
    // );

    modifier onlyWhitelisted() {
        require(_whitelistedPublishers[msg.sender], "Caller is not whitelisted");
        _;
    }

    /**
     * @notice Initialize the contract with the feed verifier address
     * @dev The feed verifier contract must be deployed first
     * @param _feedVerifier Address of the feed verifier contract
     */
    function initialize(IEOFeedVerifier _feedVerifier) external initializer {
        __Ownable_init(msg.sender);
        _feedVerifier = IEOFeedVerifier(_feedVerifier);
    }

    /**
     * @notice Set the supported symbols
     * @param symbols Array of symbols
     * @param isSupported Array of booleans indicating whether the symbol is supported
     */
    function setSupportedSymbols(string[] calldata symbols, bool[] calldata isSupported) external onlyOwner {
        for (uint256 i = 0; i < symbols.length;) {
            // TODO: check if it not already the needed value
            _supportedSymbols[symbols[i]] = isSupported[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Set the whitelisted publishers
     * @param publishers Array of publisher addresses
     * @param isWhitelisted Array of booleans indicating whether the publisher is whitelisted
     */
    // TODO: it's better to use add/remove logic for whitelisted publishers
    function whitelistPublishers(address[] memory publishers, bool[] memory isWhitelisted) external onlyOwner {
        for (uint256 i = 0; i < publishers.length;) {
            // TODO: check if it not already the needed value
            _whitelistedPublishers[publishers[i]] = isWhitelisted[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Update the price feed for a symbol
     * @param symbol Symbol of the price feed
     * @param value Price of the symbol
     * @param timestamp Timestamp of the price feed
     * @param proofData Proof data (data + proof) for the price feed
     */
    function updatePriceFeed(
        string calldata symbol,
        uint256 value,
        uint256 timestamp,
        bytes memory proofData
    )
        external
        onlyWhitelisted
    {
        require(_supportedSymbols[symbol], "Symbol is not supported");
        _feedVerifier.submitAndExit(proofData);

        _priceFeeds[symbol] = PriceFeed(value, timestamp);
    }

    /**
     * @notice Update the price feeds for multiple symbols
     * @param symbols Array of symbols
     * @param values Array of prices
     * @param timestamps Array of timestamps
     * @param proofDatas Array of proof data (data + proof) for the price feeds
     */
    function updatePriceFeeds(
        string[] calldata symbols,
        uint256[] memory values,
        uint256[] memory timestamps,
        bytes[] memory proofDatas
    )
        external
        onlyWhitelisted
    {
        require(
            symbols.length == values.length && values.length == timestamps.length
                && timestamps.length == proofDatas.length,
            "Arrays' lengths are not equal"
        );
        for (uint256 i = 0; i < symbols.length;) {
            this.updatePriceFeed(symbols[i], values[i], timestamps[i], proofDatas[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get the latest price feed for a symbol
     * @param symbol Symbol of the price feed
     * @return Price feed struct
     */
    // TODO: it is not compatible with CL
    function getLatestPriceFeed(string calldata symbol) external view override returns (PriceFeed memory) {
        require(_supportedSymbols[symbol], "Symbol is not supported");
        return _priceFeeds[symbol];
    }

    /**
     * @notice Get the latest price feeds for multiple symbols
     * @param symbols Array of symbols
     * @return Array of price feed structs
     */
    function getLatestPriceFeeds(string[] calldata symbols) external view override returns (PriceFeed[] memory) {
        PriceFeed[] memory retVal = new PriceFeed[](symbols.length);
        for (uint256 i = 0; i < symbols.length;) {
            retVal[i] = this.getLatestPriceFeed(symbols[i]);
            unchecked {
                ++i;
            }
        }
        return retVal;
    }

    /**
     * @notice Check if a publisher is whitelisted
     * @param publisher Address of the publisher
     * @return Boolean indicating whether the publisher is whitelisted
     */
    function isWhitelistedPublisher(address publisher) external view returns (bool) {
        return _whitelistedPublishers[publisher];
    }

    /**
     * @notice Check if a symbol is supported
     * @param symbol Symbol to check
     * @return Boolean indicating whether the symbol is supported
     */
    function isSupportedSymbol(string calldata symbol) external view returns (bool) {
        return _supportedSymbols[symbol];
    }

    /**
     * @notice Get the feed verifier contract address
     * @return Address of the feed verifier contract
     */
    function getFeedVerifier() external view returns (IEOFeedVerifier) {
        return _feedVerifier;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";
import { IEOFeedRegistry } from "./interfaces/IEOFeedRegistry.sol";
import {
    CallerIsNotWhitelisted,
    MissingLeafInputs,
    SymbolNotSupported,
    BlockNumberAlreadyProcessed
} from "./interfaces/Errors.sol";

contract EOFeedRegistry is Initializable, OwnableUpgradeable, IEOFeedRegistry {
    mapping(uint16 => PriceFeed) internal _priceFeeds;
    mapping(address => bool) internal _whitelistedPublishers;
    mapping(uint16 => bool) internal _supportedSymbols;
    // TODO: no setter for the _feedVerifier, is it intended?
    IEOFeedVerifier internal _feedVerifier;
    uint256 internal _lastProcessedBlockNumber;
    bytes32 internal _lastProcessedEventRoot;

    modifier onlyWhitelisted() {
        if (!_whitelistedPublishers[msg.sender]) revert CallerIsNotWhitelisted(msg.sender);
        _;
    }

    /**
     * @notice Initialize the contract with the feed verifier address
     * @dev The feed verifier contract must be deployed first
     * @param feedVerifier Address of the feed verifier contract
     * @param owner Owner of the contract
     */
    function initialize(IEOFeedVerifier feedVerifier, address owner) external initializer {
        __Ownable_init(owner);
        _feedVerifier = IEOFeedVerifier(feedVerifier);
    }

    /**
     * @notice Set the supported symbols
     * @param symbols Array of symbols
     * @param isSupported Array of booleans indicating whether the symbol is supported
     */
    function setSupportedSymbols(uint16[] calldata symbols, bool[] calldata isSupported) external onlyOwner {
        for (uint256 i = 0; i < symbols.length; i++) {
            // TODO: check if it not already the needed value
            _supportedSymbols[symbols[i]] = isSupported[i];
        }
    }

    /**
     * @notice Set the whitelisted publishers
     * @param publishers Array of publisher addresses
     * @param isWhitelisted Array of booleans indicating whether the publisher is whitelisted
     */
    // TODO: it's better to use add/remove logic for whitelisted publishers
    function whitelistPublishers(address[] memory publishers, bool[] memory isWhitelisted) external onlyOwner {
        for (uint256 i = 0; i < publishers.length; i++) {
            // TODO: check if it not already the needed value
            _whitelistedPublishers[publishers[i]] = isWhitelisted[i];
        }
    }

    /**
     * @notice Update the price feed for a symbol
     * @param input A leaf to prove the price feeds
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    // Reentrancy is not an issue because _feedVerifier is set by the owner
    // slither-disable-next-line reentrancy-benign,reentrancy-events
    function updatePriceFeed(
        IEOFeedVerifier.LeafInput memory input,
        IEOFeedVerifier.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        onlyWhitelisted
    {
        _processCheckpoint(checkpoint, signature, bitmap);

        bytes memory data = _feedVerifier.verifyLeaf(input, _lastProcessedEventRoot);
        _processVerifiedRate(data);
    }

    /**
     * @notice Update the price feeds for multiple symbols
     * @param inputs Array of leafs to prove the price feeds
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    // Reentrancy is not an issue because _feedVerifier is set by the owner
    // slither-disable-next-line reentrancy-benign,reentrancy-events
    function updatePriceFeeds(
        IEOFeedVerifier.LeafInput[] calldata inputs,
        IEOFeedVerifier.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        onlyWhitelisted
    {
        if (inputs.length == 0) revert MissingLeafInputs();
        _processCheckpoint(checkpoint, signature, bitmap);

        bytes[] memory data = _feedVerifier.verifyLeaves(inputs, _lastProcessedEventRoot);
        for (uint256 i = 0; i < data.length; i++) {
            _processVerifiedRate(data[i]);
        }
    }

    /**
     * @notice Get the latest price feed for a symbol
     * @param symbol Symbol of the price feed
     * @return Price feed struct
     */
    function getLatestPriceFeed(uint16 symbol) external view returns (PriceFeed memory) {
        return _getLatestPriceFeed(symbol);
    }

    /**
     * @notice Get the latest price feeds for multiple symbols
     * @param symbols Array of symbols
     * @return Array of price feed structs
     */
    function getLatestPriceFeeds(uint16[] calldata symbols) external view returns (PriceFeed[] memory) {
        PriceFeed[] memory retVal = new PriceFeed[](symbols.length);
        for (uint256 i = 0; i < symbols.length; i++) {
            retVal[i] = _getLatestPriceFeed(symbols[i]);
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
    function isSupportedSymbol(uint16 symbol) external view returns (bool) {
        return _supportedSymbols[symbol];
    }

    /**
     * @notice Get the feed verifier contract address
     * @return Address of the feed verifier contract
     */
    function getFeedVerifier() external view returns (IEOFeedVerifier) {
        return _feedVerifier;
    }

    function _processVerifiedRate(bytes memory data) internal {
        (uint16 symbol, uint256 rate, uint256 timestamp) = abi.decode(data, (uint16, uint256, uint256));
        if (!_supportedSymbols[symbol]) revert SymbolNotSupported(symbol);
        _priceFeeds[symbol] = PriceFeed(rate, timestamp);
        emit RateUpdated(symbol, rate, timestamp);
    }

    function _processCheckpoint(
        IEOFeedVerifier.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        internal
    {
        if (checkpoint.blockNumber < _lastProcessedBlockNumber) revert BlockNumberAlreadyProcessed();
        // if the block number has changed, we need to verify the whole checkpoint
        // Otherwise, we only need to verify the leaves
        if (checkpoint.blockNumber > _lastProcessedBlockNumber) {
            _lastProcessedBlockNumber = checkpoint.blockNumber;
            _lastProcessedEventRoot = checkpoint.eventRoot;
            _feedVerifier.verifySignature(checkpoint, signature, bitmap);
        }
    }

    function _getLatestPriceFeed(uint16 symbol) internal view returns (PriceFeed memory) {
        if (!_supportedSymbols[symbol]) revert SymbolNotSupported(symbol);
        return _priceFeeds[symbol];
    }
}

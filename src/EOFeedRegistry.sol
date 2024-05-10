// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";
import { IEOFeedRegistry } from "./interfaces/IEOFeedRegistry.sol";
import { ICheckpointManager } from "./interfaces/ICheckpointManager.sol";
import { CallerIsNotWhitelisted, MissingLeafInputs, SymbolNotSupported } from "./interfaces/Errors.sol";

contract EOFeedRegistry is Initializable, OwnableUpgradeable, IEOFeedRegistry {
    mapping(uint16 => PriceFeed) internal _priceFeeds;
    mapping(address => bool) internal _whitelistedPublishers;
    mapping(uint16 => bool) internal _supportedSymbols;
    // TODO: no setter for the _feedVerifier, is it intended?
    IEOFeedVerifier internal _feedVerifier;

    modifier onlyWhitelisted() {
        if (!_whitelistedPublishers[msg.sender]) revert CallerIsNotWhitelisted();
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
     * @param checkpointMetadata Metadata for the checkpoint
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function updatePriceFeed(
        IEOFeedVerifier.LeafInput memory input,
        ICheckpointManager.CheckpointMetadata calldata checkpointMetadata,
        ICheckpointManager.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        onlyWhitelisted
    {
        bytes memory data = _feedVerifier.submitAndVerify(input, checkpointMetadata, checkpoint, signature, bitmap);
        _processVerifiedRate(data);
    }

    /**
     * @notice Update the price feeds for multiple symbols
     * @param inputs Array of leafs to prove the price feeds
     * @param checkpointMetadata Metadata for the checkpoint
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function updatePriceFeeds(
        IEOFeedVerifier.LeafInput[] calldata inputs,
        ICheckpointManager.CheckpointMetadata calldata checkpointMetadata,
        ICheckpointManager.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        onlyWhitelisted
    {
        if (inputs.length == 0) revert MissingLeafInputs();

        bytes[] memory data =
            _feedVerifier.submitAndBatchVerify(inputs, checkpointMetadata, checkpoint, signature, bitmap);
        for (uint256 i = 0; i < data.length; i++) {
            _processVerifiedRate(data[i]);
        }
    }

    /**
     * @notice Get the latest price feed for a symbol
     * @param symbol Symbol of the price feed
     * @return Price feed struct
     */
    // TODO: it is not compatible with CL
    function getLatestPriceFeed(uint16 symbol) external view returns (PriceFeed memory) {
        if (!_supportedSymbols[symbol]) revert SymbolNotSupported();
        return _priceFeeds[symbol];
    }

    /**
     * @notice Get the latest price feeds for multiple symbols
     * @param symbols Array of symbols
     * @return Array of price feed structs
     */
    function getLatestPriceFeeds(uint16[] calldata symbols) external view returns (PriceFeed[] memory) {
        PriceFeed[] memory retVal = new PriceFeed[](symbols.length);
        for (uint256 i = 0; i < symbols.length; i++) {
            retVal[i] = this.getLatestPriceFeed(symbols[i]);
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
        if (!_supportedSymbols[symbol]) revert SymbolNotSupported();
        _priceFeeds[symbol] = PriceFeed(rate, timestamp);
    }
}

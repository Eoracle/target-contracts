// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";
import { IEOFeedManager } from "./interfaces/IEOFeedManager.sol";
import { CallerIsNotWhitelisted, MissingLeafInputs, FeedNotSupported, SymbolReplay } from "./interfaces/Errors.sol";

contract EOFeedManager is Initializable, OwnableUpgradeable, IEOFeedManager {
    mapping(uint16 => PriceFeed) internal _priceFeeds;
    mapping(address => bool) internal _whitelistedPublishers;
    mapping(uint16 => bool) internal _supportedFeedIds;
    // TODO: no setter for the _feedVerifier, is it intended?
    IEOFeedVerifier internal _feedVerifier;

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
     * @notice Set the supported feeds
     * @param feedIds Array of feed ids
     * @param isSupported Array of booleans indicating whether the feed is supported
     */
    function setSupportedFeeds(uint16[] calldata feedIds, bool[] calldata isSupported) external onlyOwner {
        for (uint256 i = 0; i < feedIds.length; i++) {
            // TODO: check if it not already the needed value
            _supportedFeedIds[feedIds[i]] = isSupported[i];
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
     * @notice Update the price for a feed
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
        bytes memory data = _feedVerifier.verify(input, checkpoint, signature, bitmap);
        _processVerifiedRate(data);
    }

    /**
     * @notice Update the price for multiple feeds
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

        bytes[] memory data = _feedVerifier.batchVerify(inputs, checkpoint, signature, bitmap);
        for (uint256 i = 0; i < data.length; i++) {
            _processVerifiedRate(data[i]);
        }
    }

    /**
     * @notice Get the latest price for a feed
     * @param feedId Feed id
     * @return PriceFeed struct
     */
    function getLatestPriceFeed(uint16 feedId) external view returns (PriceFeed memory) {
        return _getLatestPriceFeed(feedId);
    }

    /**
     * @notice Get the latest price feeds for multiple feeds
     * @param feedIds Array of feed ids
     * @return Array of price feed structs
     */
    function getLatestPriceFeeds(uint16[] calldata feedIds) external view returns (PriceFeed[] memory) {
        PriceFeed[] memory retVal = new PriceFeed[](feedIds.length);
        for (uint256 i = 0; i < feedIds.length; i++) {
            retVal[i] = _getLatestPriceFeed(feedIds[i]);
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
     * @notice Check if a feed is supported
     * @param feedId feed Id to check
     * @return Boolean indicating whether the feed is supported
     */
    function isSupportedFeed(uint16 feedId) external view returns (bool) {
        return _supportedFeedIds[feedId];
    }

    /**
     * @notice Get the feed verifier contract address
     * @return Address of the feed verifier contract
     */
    function getFeedVerifier() external view returns (IEOFeedVerifier) {
        return _feedVerifier;
    }

    function _processVerifiedRate(bytes memory data) internal {
        (uint16 feedId, uint256 rate, uint256 timestamp) = abi.decode(data, (uint16, uint256, uint256));
        if (!_supportedFeedIds[feedId]) revert FeedNotSupported(feedId);
        if (_priceFeeds[feedId].timestamp >= timestamp) revert SymbolReplay(feedId);
        _priceFeeds[feedId] = PriceFeed(rate, timestamp);
        emit RateUpdated(feedId, rate, timestamp);
    }

    function _getLatestPriceFeed(uint16 feedId) internal view returns (PriceFeed memory) {
        if (!_supportedFeedIds[feedId]) revert FeedNotSupported(feedId);
        return _priceFeeds[feedId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";
import { IEOFeedManager } from "./interfaces/IEOFeedManager.sol";
import {
    InvalidAddress,
    CallerIsNotWhitelisted,
    MissingLeafInputs,
    FeedNotSupported,
    SymbolReplay,
    InvalidInput
} from "./interfaces/Errors.sol";

/**
 * @title EOFeedManager
 * @notice The EOFeedManager contract is responsible for receiving feed updates from whitelisted publishers. These
 * updates are verified using the logic in the EOFeedVerifier. Upon successful verification, the feed data is stored in
 * the EOFeedManager and made available for other smart contracts to read. Only supported feed IDs can be published to
 * the feed manager.
 */
contract EOFeedManager is IEOFeedManager, OwnableUpgradeable {
    /// @dev Map of feed id to price feed (feed id => PriceFeed)
    mapping(uint16 => PriceFeed) internal _priceFeeds;

    /// @dev Map of whitelisted publishers (publisher => is whitelisted)
    mapping(address => bool) internal _whitelistedPublishers;

    /// @dev Map of supported feeds, (feed id => is supported)
    mapping(uint16 => bool) internal _supportedFeedIds;

    /// @dev feed verifier contract
    IEOFeedVerifier internal _feedVerifier;

    /// @dev Allows only whitelisted publishers to call the function
    modifier onlyWhitelisted() {
        if (!_whitelistedPublishers[msg.sender]) revert CallerIsNotWhitelisted(msg.sender);
        _;
    }

    /// @dev Allows only non-zero addresses
    modifier onlyNonZeroAddress(address addr) {
        if (addr == address(0)) revert InvalidAddress();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract with the feed verifier address
     * @dev The feed verifier contract must be deployed first
     * @param feedVerifier Address of the feed verifier contract
     * @param owner Owner of the contract
     */
    function initialize(address feedVerifier, address owner) external onlyNonZeroAddress(feedVerifier) initializer {
        __Ownable_init(owner);
        _feedVerifier = IEOFeedVerifier(feedVerifier);
    }

    /**
     * @notice Set the feed verifier contract address
     * @param feedVerifier Address of the feed verifier contract
     */
    function setFeedVerifier(address feedVerifier) external onlyOwner onlyNonZeroAddress(feedVerifier) {
        _feedVerifier = IEOFeedVerifier(feedVerifier);
    }

    /**
     * @notice Set the supported feeds
     * @param feedIds Array of feed ids
     * @param isSupported Array of booleans indicating whether the feed is supported
     */
    function setSupportedFeeds(uint16[] calldata feedIds, bool[] calldata isSupported) external onlyOwner {
        if (feedIds.length != isSupported.length) revert InvalidInput();
        for (uint256 i = 0; i < feedIds.length; i++) {
            _supportedFeedIds[feedIds[i]] = isSupported[i];
        }
    }

    /**
     * @inheritdoc IEOFeedManager
     */
    function whitelistPublishers(address[] memory publishers, bool[] memory isWhitelisted) external onlyOwner {
        if (publishers.length != isWhitelisted.length) revert InvalidInput();
        for (uint256 i = 0; i < publishers.length; i++) {
            if (publishers[i] == address(0)) revert InvalidAddress();
            _whitelistedPublishers[publishers[i]] = isWhitelisted[i];
        }
    }

    /**
     * @inheritdoc IEOFeedManager
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
        _processVerifiedRate(data, checkpoint.blockNumber);
    }

    /**
     * @inheritdoc IEOFeedManager
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
            _processVerifiedRate(data[i], checkpoint.blockNumber);
        }
    }

    /**
     * @inheritdoc IEOFeedManager
     */
    function getLatestPriceFeed(uint16 feedId) external view returns (PriceFeed memory) {
        return _getLatestPriceFeed(feedId);
    }

    /**
     * @inheritdoc IEOFeedManager
     */
    function getLatestPriceFeeds(uint16[] calldata feedIds) external view returns (PriceFeed[] memory) {
        PriceFeed[] memory retVal = new PriceFeed[](feedIds.length);
        for (uint256 i = 0; i < feedIds.length; i++) {
            retVal[i] = _getLatestPriceFeed(feedIds[i]);
        }
        return retVal;
    }

    /**
     * @inheritdoc IEOFeedManager
     */
    function isWhitelistedPublisher(address publisher) external view returns (bool) {
        return _whitelistedPublishers[publisher];
    }

    /**
     * @inheritdoc IEOFeedManager
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

    /**
     * @notice Process the verified rate, check and save it
     * @param data Verified rate data, abi encoded (uint16 feedId, uint256 rate, uint256 timestamp)
     * @param blockNumber eoracle chain block number
     */
    function _processVerifiedRate(bytes memory data, uint256 blockNumber) internal {
        (uint16 feedId, uint256 rate, uint256 timestamp) = abi.decode(data, (uint16, uint256, uint256));
        if (!_supportedFeedIds[feedId]) revert FeedNotSupported(feedId);
        if (_priceFeeds[feedId].timestamp >= timestamp) revert SymbolReplay(feedId);
        _priceFeeds[feedId] = PriceFeed(rate, timestamp, blockNumber);
        emit RateUpdated(feedId, rate, timestamp);
    }

    /**
     * @notice Get the latest price feed
     * @param feedId Feed id
     * @return PriceFeed struct
     */
    function _getLatestPriceFeed(uint16 feedId) internal view returns (PriceFeed memory) {
        if (!_supportedFeedIds[feedId]) revert FeedNotSupported(feedId);
        return _priceFeeds[feedId];
    }

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

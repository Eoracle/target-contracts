// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IEOFeedManager } from "../interfaces/IEOFeedManager.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IEOFeedAdapter } from "./interfaces/IEOFeedAdapter.sol";
import { IEOFeedRegistryAdapter } from "./interfaces/IEOFeedRegistryAdapter.sol";
import { EOFeedFactoryBase } from "./factories/EOFeedFactoryBase.sol";
import { InvalidAddress, FeedAlreadyExists, BaseQuotePairExists, FeedNotSupported } from "../interfaces/Errors.sol";

/**
 * @title EOFeedRegistryAdapterBase
 * @notice base contract which is adapter of EOFeedManager contract for CL FeedManager
 */
abstract contract EOFeedRegistryAdapterBase is OwnableUpgradeable, EOFeedFactoryBase, IEOFeedRegistryAdapter {
    IEOFeedManager internal _feedManager;
    mapping(uint16 => IEOFeedAdapter) internal _feedAdapters;
    mapping(address => bool) internal _feedEnabled;
    mapping(address => mapping(address => uint16)) internal _tokenAddressesToFeedIds;

    event FeedManagerSet(address indexed feedManager);
    event FeedAdapterDeployed(uint16 indexed feedId, address indexed feedAdapter, address base, address quote);

    modifier onlyNonZeroAddress(address addr) {
        if (addr == address(0)) revert InvalidAddress();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract
     * @param feedManager The feed manager address
     * @param feedAdapterImplementation The feedAdapter implementation address
     * @param owner Owner of the contract
     */
    function initialize(
        address feedManager,
        address feedAdapterImplementation,
        address owner
    )
        external
        initializer
        onlyNonZeroAddress(feedManager)
        onlyNonZeroAddress(feedAdapterImplementation)
    {
        __Ownable_init(owner);
        __EOFeedFactory_init(feedAdapterImplementation, owner);
        _feedManager = IEOFeedManager(feedManager);
        emit FeedManagerSet(feedManager);
    }

    /**
     * @notice Set the feed manager
     * @param feedManager The feed manager address
     */
    function setFeedManager(address feedManager) external onlyOwner onlyNonZeroAddress(feedManager) {
        _feedManager = IEOFeedManager(feedManager);
        emit FeedManagerSet(feedManager);
    }

    /**
     * @notice deploy EOFeedAdapter
     * @param base The base asset address
     * @param quote The quote asset address
     * @param feedId The feed id
     * @param feedDescription The description of feed
     * @param inputDecimals The input decimals
     * @param outputDecimals The output decimals
     * @param feedVersion The version of the feed
     * @return IEOFeedAdapter The feed adapter
     */
    // This function can reenter through the external call to the deployed EOFeedAdapter, but the external contract is
    // being deployed by this contract, so it is considered safe
    // slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events
    function deployEOFeedAdapter(
        address base,
        address quote,
        uint16 feedId,
        string calldata feedDescription,
        uint8 inputDecimals,
        uint8 outputDecimals,
        uint256 feedVersion
    )
        external
        onlyOwner
        returns (IEOFeedAdapter)
    {
        // check if feedId exists in feedManager contract
        if (!_feedManager.isSupportedFeed(feedId)) {
            revert FeedNotSupported(feedId);
        }

        if (address(_feedAdapters[feedId]) != address(0)) {
            revert FeedAlreadyExists();
        }
        if (_tokenAddressesToFeedIds[base][quote] != 0) {
            revert BaseQuotePairExists();
        }
        address feedAdapter = _deployEOFeedAdapter();
        IEOFeedAdapter(feedAdapter).initialize(
            address(_feedManager), feedId, inputDecimals, outputDecimals, feedDescription, feedVersion
        );

        _feedEnabled[feedAdapter] = true;
        _feedAdapters[feedId] = IEOFeedAdapter(feedAdapter);
        _tokenAddressesToFeedIds[base][quote] = feedId;

        emit FeedAdapterDeployed(feedId, feedAdapter, base, quote);

        return IEOFeedAdapter(feedAdapter);
    }

    /**
     * @notice Get the feed manager
     * @return IEOFeedManager The feed manager
     */
    function getFeedManager() external view returns (IEOFeedManager) {
        return _feedManager;
    }

    /**
     * @notice Get the feedAdapter for a given id
     * @param feedId The feed id
     * @return IEOFeedAdapter The feedAdapter
     */
    function getFeedById(uint16 feedId) external view returns (IEOFeedAdapter) {
        return _feedAdapters[feedId];
    }

    /**
     * @notice Get the decimals for a given base/quote pair
     * @dev Calls the decimals function from the feedAdapter itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return uint8 The decimals
     */
    function decimals(address base, address quote) external view returns (uint8) {
        return _feedAdapters[_tokenAddressesToFeedIds[base][quote]].decimals();
    }

    /**
     * @notice Get the description for a given base/quote pair
     * @dev Calls the description function from the feedAdapter itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return string The description
     */
    function description(address base, address quote) external view returns (string memory) {
        return _feedAdapters[_tokenAddressesToFeedIds[base][quote]].description();
    }

    /**
     * @notice Get the version for a given base/quote pair
     * @dev Calls the version function from the feedAdapter itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return uint256 The version
     */
    function version(address base, address quote) external view returns (uint256) {
        return _feedAdapters[_tokenAddressesToFeedIds[base][quote]].version();
    }

    /**
     * @notice Get the latest round data for a given base/quote pair
     * @dev Calls the getLatestPriceFeed function from the feed manager, not from feedAdapter itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return roundId The roundId
     * @return answer The answer
     * @return startedAt The startedAt
     * @return updatedAt The updatedAt
     * @return answeredInRound The answeredInRound
     */
    function latestRoundData(
        address base,
        address quote
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        IEOFeedManager.PriceFeed memory feedData =
            _feedManager.getLatestPriceFeed(_tokenAddressesToFeedIds[base][quote]);
        return (
            uint80(feedData.eoracleBlockNumber),
            int256(feedData.value),
            feedData.timestamp,
            feedData.timestamp,
            uint80(feedData.eoracleBlockNumber)
        );
    }

    /**
     * @notice Get the round data for a given base/quote pair
     * @dev Calls the getLatestPriceFeed function from the feed manager, not from feedAdapter itself
     *      currently the roundId is not used and latest round is returned
     * @param base The base asset address
     * @param quote The quote asset address
     * @return roundId The roundId
     * @return answer The answer
     * @return startedAt The startedAt
     * @return updatedAt The updatedAt
     * @return answeredInRound The answeredInRound
     */
    function getRoundData(
        address base,
        address quote,
        uint80
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        IEOFeedManager.PriceFeed memory feedData =
            _feedManager.getLatestPriceFeed(_tokenAddressesToFeedIds[base][quote]);
        return (
            uint80(feedData.eoracleBlockNumber),
            int256(feedData.value),
            feedData.timestamp,
            feedData.timestamp,
            uint80(feedData.eoracleBlockNumber)
        );
    }

    /**
     * @notice Get the latest price for a given base/quote pair
     * @dev Calls the getLatestPriceFeed function from the feed manager, not from feedAdapter itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return int256 The latest price
     */
    function latestAnswer(address base, address quote) external view override returns (int256) {
        return int256(_feedManager.getLatestPriceFeed(_tokenAddressesToFeedIds[base][quote]).value);
    }

    /**
     * @notice Get the latest timestamp for a given base/quote pair
     * @dev Calls the getLatestPriceFeed function from the feed manager, not from feedAdapter itself
     * @param base The base asset address
     * @param quote The quote asset address
     * @return uint256 The latest timestamp
     */
    function latestTimestamp(address base, address quote) external view returns (uint256) {
        return _feedManager.getLatestPriceFeed(_tokenAddressesToFeedIds[base][quote]).timestamp;
    }

    /**
     * @notice Get the answer for a given base/quote pair and round
     * @dev Calls the getLatestPriceFeed function from the feed manager, not from feedAdapter itself
     *      currently the roundId is not used and latest answer is returned
     * @param base The base asset address
     * @param quote The quote asset address
     * @param
     * @return int256 The answer
     */
    function getAnswer(address base, address quote, uint256) external view returns (int256) {
        return int256(_feedManager.getLatestPriceFeed(_tokenAddressesToFeedIds[base][quote]).value);
    }

    /**
     * @notice Get the timestamp for a given base/quote pair and round
     * @dev Calls the getLatestPriceFeed function from the feed manager, not from feedAdapter itself
     *      currently the roundId is not used and latest timestamp is returned
     * @param base The base asset address
     * @param quote The quote asset address
     * @param
     * @return uint256 The timestamp
     */
    function getTimestamp(address base, address quote, uint256) external view returns (uint256) {
        return _feedManager.getLatestPriceFeed(_tokenAddressesToFeedIds[base][quote]).timestamp;
    }

    /**
     * @notice Get the feedAdapter for a given base/quote pair
     * @param base The base asset address
     * @param quote The quote asset address
     * @return IEOFeedAdapter The feedAdapter
     */
    function getFeed(address base, address quote) external view override returns (IEOFeedAdapter) {
        return _getFeed(base, quote);
    }

    /**
     * @notice Check if a feedAdapter is enabled in the storage of adapter
     * @param feedAdapter The feedAdapter address
     * @return bool True if the feedAdapter is enabled
     */
    function isFeedEnabled(address feedAdapter) external view returns (bool) {
        return _feedEnabled[feedAdapter];
    }

    /**
     * @notice Get the round feedAdapter for a given base/quote pair
     * @param base The base asset address
     * @param quote The quote asset address
     * @param
     * @return IEOFeedAdapter The feedAdapter
     */
    function getRoundFeed(address base, address quote, uint80) external view returns (IEOFeedAdapter) {
        return _getFeed(base, quote);
    }

    /**
     * @notice Get the latest round for a given base/quote pair
     * @dev Calls the getLatestPriceFeed function from the feed manager, not from Feed itself
     *      currently the roundId is not used and 0 is returned
     * @param base The base asset address
     * @param quote The quote asset address
     * @return uint256 The latest round
     */
    function latestRound(address base, address quote) external view returns (uint256) {
        return _feedManager.getLatestPriceFeed(_tokenAddressesToFeedIds[base][quote]).eoracleBlockNumber;
    }

    /**
     * @notice Get the feedAdapter for a given base/quote pair
     * @param base The base asset address
     * @param quote The quote asset address
     * @return IEOFeedAdapter The feedAdapter
     */
    function _getFeed(address base, address quote) internal view returns (IEOFeedAdapter) {
        return _feedAdapters[_tokenAddressesToFeedIds[base][quote]];
    }

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

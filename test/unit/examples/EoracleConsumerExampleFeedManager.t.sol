// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { EoracleConsumerExampleFeedManager } from "../../../src/examples/EoracleConsumerExampleFeedManager.sol";
import { MockEOFeedManager } from "../../mock/MockEOFeedManager.sol";
import { IEOFeedManager } from "../../../src/interfaces/IEOFeedManager.sol";
import { IEOFeedVerifier } from "../../../src/interfaces/IEOFeedVerifier.sol";
// solhint-disable ordering

contract EoracleConsumerExampleFeedManagerTest is Test {
    uint8 public constant DECIMALS = 8;
    uint16 public constant FEED_ID = 1;
    string public constant DESCRIPTION = "ETH/USD";
    uint256 public constant VERSION = 1;
    uint256 public constant RATE1 = 100_000_000;
    uint256 public constant RATE2 = 200_000_000;

    IEOFeedManager internal _feedManager;
    EoracleConsumerExampleFeedManager internal _consumerExampleFeedManager;
    address internal _owner;
    uint256 internal _lastTimestamp;

    function setUp() public virtual {
        _owner = makeAddr("_owner");

        _feedManager = new MockEOFeedManager();
        _consumerExampleFeedManager = new EoracleConsumerExampleFeedManager(address(_feedManager));

        _updatePriceFeed(FEED_ID, RATE1, block.timestamp);
        _lastTimestamp = block.timestamp;
    }

    function test_SetGetFeedManager() public {
        address newFeedManager = makeAddr("_feedManager");
        _consumerExampleFeedManager.setFeedManager(newFeedManager);
        assertEq(address(_consumerExampleFeedManager.getFeedManager()), newFeedManager);
    }

    function test_GetPrice() public view {
        IEOFeedManager.PriceFeed memory priceFeed = _consumerExampleFeedManager.getPrice(FEED_ID);
        assertEq(priceFeed.value, RATE1);
        assertEq(priceFeed.timestamp, _lastTimestamp);
    }

    function test_GetPrices() public view {
        uint16[] memory feedIds = new uint16[](1);
        feedIds[0] = FEED_ID;
        IEOFeedManager.PriceFeed[] memory priceFeeds = _consumerExampleFeedManager.getPrices(feedIds);
        assertEq(priceFeeds.length, 1);
        assertEq(priceFeeds[0].value, RATE1);
        assertEq(priceFeeds[0].timestamp, _lastTimestamp);
    }

    function _updatePriceFeed(uint16 feedId, uint256 rate, uint256 timestamp) internal {
        IEOFeedVerifier.LeafInput memory input;
        input.unhashedLeaf = abi.encode(feedId, rate, timestamp);
        _feedManager.updatePriceFeed(
            input,
            IEOFeedVerifier.Checkpoint({
                blockNumber: 0,
                epoch: 0,
                eventRoot: bytes32(0),
                blockHash: bytes32(0),
                blockRound: 0
            }),
            [uint256(0), uint256(0)],
            bytes("0")
        );
    }
}

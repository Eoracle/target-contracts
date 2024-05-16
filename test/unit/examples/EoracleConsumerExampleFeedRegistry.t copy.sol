// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { EOFeed } from "../../../src/adapters/EOFeed.sol";
import { EoracleConsumerExampleFeedRegistry } from "../../../src/examples/EoracleConsumerExampleFeedRegistry.sol";
import { MockEOFeedRegistry } from "../../mock/MockEOFeedRegistry.sol";
import { IEOFeedRegistry } from "../../../src/interfaces/IEOFeedRegistry.sol";
import { IEOFeedVerifier } from "../../../src/interfaces/IEOFeedVerifier.sol";
// solhint-disable ordering

contract EoracleConsumerExampleFeedRegistryTest is Test {
    EOFeed public feed;
    IEOFeedRegistry public feedRegistry;
    EoracleConsumerExampleFeedRegistry public consumerExampleFeedRegistry;
    address internal _owner;
    uint8 internal _decimals = 8;
    uint16 internal _pairSymbol = 1;
    string internal _description = "ETH/USD";
    uint256 internal _version = 1;
    uint256 internal _lastTimestamp;
    uint256 internal constant RATE1 = 100_000_000;
    uint256 internal constant RATE2 = 200_000_000;

    function setUp() public virtual {
        _owner = makeAddr("_owner");

        feedRegistry = new MockEOFeedRegistry();
        consumerExampleFeedRegistry = new EoracleConsumerExampleFeedRegistry(address(feedRegistry));

        _updatePriceFeed(_pairSymbol, RATE1, block.timestamp);
        _lastTimestamp = block.timestamp;
    }

    function test_SetGetFeedRegistry() public {
        address newFeedRegistry = makeAddr("_feedRegistry");
        consumerExampleFeedRegistry.setFeedRegistry(newFeedRegistry);
        assertEq(address(consumerExampleFeedRegistry.getFeedRegistry()), newFeedRegistry);
    }

    function test_GetPrice() public view {
        IEOFeedRegistry.PriceFeed memory priceFeed = consumerExampleFeedRegistry.getPrice(_pairSymbol);
        assertEq(priceFeed.value, RATE1);
        assertEq(priceFeed.timestamp, _lastTimestamp);
    }

    function test_GetPrices() public view {
        uint16[] memory symbols = new uint16[](1);
        symbols[0] = _pairSymbol;
        IEOFeedRegistry.PriceFeed[] memory priceFeeds = consumerExampleFeedRegistry.getPrices(symbols);
        assertEq(priceFeeds.length, 1);
        assertEq(priceFeeds[0].value, RATE1);
        assertEq(priceFeeds[0].timestamp, _lastTimestamp);
    }

    function _updatePriceFeed(uint16 pairSymbol, uint256 rate, uint256 timestamp) internal {
        IEOFeedVerifier.LeafInput memory input;
        input.unhashedLeaf = abi.encode(pairSymbol, rate, timestamp);
        feedRegistry.updatePriceFeed(
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

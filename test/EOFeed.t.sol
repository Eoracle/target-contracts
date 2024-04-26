// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { EOFeed } from "../src/adapters/EOFeed.sol";
import { MockEOFeedRegistry } from "./mock/MockEOFeedRegistry.sol";
import { IEOFeedRegistry } from "../src/interfaces/IEOFeedRegistry.sol";

contract EOFeedTest is Test {
    EOFeed public feed;
    IEOFeedRegistry public feedRegistry;
    address internal _owner;
    uint8 internal _decimals = 8;
    string internal _description_ = "ETH/USD";
    uint256 internal _version = 1;
    uint256 internal _lastTimestamp;
    uint256 internal constant RATE1 = 100_000_000;
    uint256 internal constant RATE2 = 200_000_000;

    function setUp() public {
        _owner = makeAddr("_owner");

        feedRegistry = new MockEOFeedRegistry();
        feed = new EOFeed();
        feed.initialize(feedRegistry, _decimals, _description_, _version);
        feedRegistry.updatePriceFeed(_description_, RATE1, block.timestamp, "");
        _lastTimestamp = block.timestamp;
    }

    function testGetRoundData() public {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.getRoundData(1);
        assertEq(roundId, 1);
        assertEq(answer, int256(RATE1));
        assertEq(startedAt, 0);
        assertEq(updatedAt, _lastTimestamp);
        assertEq(answeredInRound, 1);
    }

    function testLatestRoundData() public {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();
        assertEq(roundId, 0);
        assertEq(answer, int256(RATE1));
        assertEq(startedAt, 0);
        assertEq(updatedAt, _lastTimestamp);
        assertEq(answeredInRound, 0);
    }

    function testGetRoundData2() public {
        feedRegistry.updatePriceFeed(_description_, RATE2, block.timestamp, "");
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.getRoundData(2);
        assertEq(roundId, 2);
        assertEq(answer, int256(RATE2));
        assertEq(startedAt, 0);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 2);
    }

    function testLatestRoundData2() public {
        feedRegistry.updatePriceFeed(_description_, RATE2, block.timestamp, "");
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();
        assertEq(roundId, 0);
        assertEq(answer, int256(RATE2));
        assertEq(startedAt, 0);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 0);
    }

    function testDecimals() public {
        assertEq(feed.decimals(), _decimals);
    }

    function testDescription() public {
        assertEq(feed.description(), _description_);
    }

    function testVersion() public {
        assertEq(feed.version(), _version);
    }

    function testGetRoundDataFuzz(uint256 rate, uint256 timestamp) public {
        feedRegistry.updatePriceFeed(_description_, rate, timestamp, "");
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.getRoundData(3);
        assertEq(roundId, 3);
        assertEq(answer, int256(rate));
        assertEq(startedAt, 0);
        assertEq(updatedAt, timestamp);
        assertEq(answeredInRound, 3);
    }

    function testLatestRoundDataFuzz(uint256 rate, uint256 timestamp) public {
        feedRegistry.updatePriceFeed(_description_, rate, timestamp, "");
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();
        assertEq(roundId, 0);
        assertEq(answer, int256(rate));
        assertEq(startedAt, 0);
        assertEq(updatedAt, timestamp);
        assertEq(answeredInRound, 0);
    }
}

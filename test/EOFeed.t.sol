// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { EOFeed } from "../src/adapters/EOFeed.sol";
import { MockEOFeedRegistry } from "./mock/MockEOFeedRegistry.sol";
import { IEOFeedRegistry } from "../src/interfaces/IEOFeedRegistry.sol";

// solhint-disable ordering
contract EOFeedTest is Test {
    EOFeed public feed;
    IEOFeedRegistry public feedRegistry;
    address internal _owner;
    uint8 internal _decimals = 8;
    string internal _description = "ETH/USD";
    uint256 internal _version = 1;
    uint256 internal _lastTimestamp;
    uint256 internal constant RATE1 = 100_000_000;
    uint256 internal constant RATE2 = 200_000_000;

    function setUp() public virtual {
        _owner = makeAddr("_owner");

        feedRegistry = new MockEOFeedRegistry();
        feed = new EOFeed();
        feed.initialize(feedRegistry, _description, _decimals, _description, _version);
        feedRegistry.updatePriceFeed(_description, RATE1, block.timestamp, "");
        _lastTimestamp = block.timestamp;
    }

    function test_GetRoundData() public view {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.getRoundData(1);
        assertEq(roundId, 0);
        assertEq(answer, int256(RATE1));
        assertEq(startedAt, 0);
        assertEq(updatedAt, _lastTimestamp);
        assertEq(answeredInRound, 0);
    }

    function test_LatestRoundData() public view {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();
        assertEq(roundId, 0);
        assertEq(answer, int256(RATE1));
        assertEq(startedAt, 0);
        assertEq(updatedAt, _lastTimestamp);
        assertEq(answeredInRound, 0);
    }

    function test_GetRoundData2() public {
        feedRegistry.updatePriceFeed(_description, RATE2, block.timestamp, "");
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.getRoundData(2);
        assertEq(roundId, 0);
        assertEq(answer, int256(RATE2));
        assertEq(startedAt, 0);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 0);
    }

    function test_LatestRoundData2() public {
        feedRegistry.updatePriceFeed(_description, RATE2, block.timestamp, "");
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();
        assertEq(roundId, 0);
        assertEq(answer, int256(RATE2));
        assertEq(startedAt, 0);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, 0);
    }

    function test_Decimals() public view {
        assertEq(feed.decimals(), _decimals);
    }

    function test_Description() public view {
        assertEq(feed.description(), _description);
    }

    function test_Version() public view {
        assertEq(feed.version(), _version);
    }

    function testFuzz_GetRoundData(uint256 rate, uint256 timestamp) public {
        feedRegistry.updatePriceFeed(_description, rate, timestamp, "");
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.getRoundData(3);
        assertEq(roundId, 0);
        assertEq(answer, int256(rate));
        assertEq(startedAt, 0);
        assertEq(updatedAt, timestamp);
        assertEq(answeredInRound, 0);
    }

    function testFuzz_LatestRoundData(uint256 rate, uint256 timestamp) public {
        feedRegistry.updatePriceFeed(_description, rate, timestamp, "");
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feed.latestRoundData();
        assertEq(roundId, 0);
        assertEq(answer, int256(rate));
        assertEq(startedAt, 0);
        assertEq(updatedAt, timestamp);
        assertEq(answeredInRound, 0);
    }
}

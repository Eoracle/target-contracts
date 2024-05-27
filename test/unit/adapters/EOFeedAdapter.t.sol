// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { EOFeedAdapter } from "../../../src/adapters/EOFeedAdapter.sol";
import { MockEOFeedManager } from "../../mock/MockEOFeedManager.sol";
import { IEOFeedManager } from "../../../src/interfaces/IEOFeedManager.sol";
import { IEOFeedVerifier } from "../../../src/interfaces/IEOFeedVerifier.sol";
// solhint-disable ordering

contract EOFeedAdapterTest is Test {
    uint8 public constant DECIMALS = 8;
    string public constant DESCRIPTION = "ETH/USD";
    uint256 public constant VERSION = 1;
    uint16 public constant FEED_ID = 1;
    uint256 public constant RATE1 = 100_000_000;
    uint256 public constant RATE2 = 200_000_000;

    EOFeedAdapter internal _feedAdapter;
    IEOFeedManager internal _feedManager;
    address internal _owner;
    uint256 internal _lastTimestamp;
    uint256 internal _lastBlockNumber;

    function setUp() public virtual {
        _owner = makeAddr("_owner");

        _feedManager = new MockEOFeedManager();
        _feedAdapter = new EOFeedAdapter();
        _feedAdapter.initialize(address(_feedManager), FEED_ID, DECIMALS, DESCRIPTION, VERSION);
        _lastTimestamp = block.timestamp;
        _lastBlockNumber = block.number;
        _updatePriceFeed(FEED_ID, RATE1, block.timestamp);
    }

    function test_GetRoundData() public view {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            _feedAdapter.getRoundData(1);
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, int256(RATE1));
        assertEq(startedAt, _lastTimestamp);
        assertEq(updatedAt, _lastTimestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function test_LatestRoundData() public view {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            _feedAdapter.latestRoundData();
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, int256(RATE1));
        assertEq(startedAt, _lastTimestamp);
        assertEq(updatedAt, _lastTimestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function test_LatestAnswer() public view {
        assertEq(_feedAdapter.latestAnswer(), int256(RATE1));
    }

    function test_LatestTimestamp() public view {
        assertEq(_feedAdapter.latestTimestamp(), _lastTimestamp);
    }

    function test_LatestRound() public view {
        assertEq(_feedAdapter.latestRound(), _lastBlockNumber);
    }

    function test_GetAnswer() public view {
        assertEq(_feedAdapter.getAnswer(1), int256(RATE1));
    }

    function test_GetTimestamp() public view {
        assertEq(_feedAdapter.getTimestamp(1), _lastTimestamp);
    }

    function test_Decimals() public view {
        assertEq(_feedAdapter.decimals(), DECIMALS);
    }

    function test_Description() public view {
        assertEq(_feedAdapter.description(), DESCRIPTION);
    }

    function test_Version() public view {
        assertEq(_feedAdapter.version(), VERSION);
    }

    function test_UpdatePrice() public {
        _updatePriceFeed(FEED_ID, RATE2, block.timestamp);
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            _feedAdapter.getRoundData(2);
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, int256(RATE2));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, _lastBlockNumber);

        (roundId, answer, startedAt, updatedAt, answeredInRound) = _feedAdapter.latestRoundData();
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, int256(RATE2));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, _lastBlockNumber);

        assertEq(_feedAdapter.latestAnswer(), int256(RATE2));
        assertEq(_feedAdapter.latestTimestamp(), block.timestamp);
        assertEq(_feedAdapter.latestRound(), _lastBlockNumber);
        assertEq(_feedAdapter.getAnswer(2), int256(RATE2));
        assertEq(_feedAdapter.getTimestamp(2), block.timestamp);
    }

    function testFuzz_GetRoundData(uint256 rate, uint256 timestamp) public {
        _updatePriceFeed(FEED_ID, rate, timestamp);
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            _feedAdapter.getRoundData(3);
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, int256(rate));
        assertEq(startedAt, timestamp);
        assertEq(updatedAt, timestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function testFuzz_LatestRoundData(uint256 rate, uint256 timestamp) public {
        _updatePriceFeed(FEED_ID, rate, timestamp);
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            _feedAdapter.latestRoundData();
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, int256(rate));
        assertEq(startedAt, timestamp);
        assertEq(updatedAt, timestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function _updatePriceFeed(uint16 feedId, uint256 rate, uint256 timestamp) internal {
        IEOFeedVerifier.LeafInput memory input;
        input.unhashedLeaf = abi.encode(feedId, rate, timestamp);
        _feedManager.updatePriceFeed(
            input,
            IEOFeedVerifier.Checkpoint({
                blockNumber: _lastBlockNumber,
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

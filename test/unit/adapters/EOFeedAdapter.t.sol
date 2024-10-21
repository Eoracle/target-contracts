// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { EOFeedAdapter } from "../../../src/adapters/EOFeedAdapter.sol";
import { MockEOFeedManager } from "../../mock/MockEOFeedManager.sol";
import { IEOFeedManager } from "../../../src/interfaces/IEOFeedManager.sol";
import { IEOFeedVerifier } from "../../../src/interfaces/IEOFeedVerifier.sol";

import { InvalidDecimals, InvalidAddress } from "../../../src/interfaces/Errors.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Options } from "openzeppelin-foundry-upgrades/Options.sol";

// solhint-disable ordering

abstract contract EOFeedAdapterTestUninitialized is Test {
    Options public opts;
    uint8 public constant DECIMALS = 8;
    string public constant DESCRIPTION = "ETH/USD";
    uint256 public constant VERSION = 1;
    uint16 public constant FEED_ID = 1;
    uint256 public constant RATE1 = 100_000_000_000_000_000;
    uint256 public constant RATE2 = 200_000_000_000_000_000;
    address public proxyAdmin = makeAddr("proxyAdmin");

    EOFeedAdapter internal _feedAdapter;
    IEOFeedManager internal _feedManager;
    address internal _owner;
    uint256 internal _lastTimestamp;
    uint256 internal _lastBlockNumber;

    function setUp() public virtual {
        _owner = makeAddr("_owner");

        _feedManager = new MockEOFeedManager();
        _feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));

        _lastTimestamp = block.timestamp;
        _lastBlockNumber = block.number;
    }
}

contract EOFeedAdapterInitializationTest is EOFeedAdapterTestUninitialized {
    function test_Initialize() public {
        _feedAdapter.initialize(address(_feedManager), FEED_ID, DECIMALS, DECIMALS, DESCRIPTION, VERSION);
        assertEq(_feedAdapter.getFeedId(), FEED_ID);
        assertEq(_feedAdapter.decimals(), DECIMALS);
        assertEq(_feedAdapter.description(), DESCRIPTION);
        assertEq(_feedAdapter.version(), VERSION);
    }

    function test_RevertWhen_ZeroAddress_Initialize() public {
        vm.expectRevert(InvalidAddress.selector);
        _feedAdapter.initialize(address(0), FEED_ID, DECIMALS, DECIMALS, DESCRIPTION, VERSION);
    }

    function test_RevertWhen_InputDecimalsTooLarge_Initialize() public {
        vm.expectRevert(InvalidDecimals.selector);
        _feedAdapter.initialize(address(_feedManager), FEED_ID, 19, DECIMALS, DESCRIPTION, VERSION);
    }

    function test_RevertWhen_InputDecimalsZero_Initialize() public {
        vm.expectRevert(InvalidDecimals.selector);
        _feedAdapter.initialize(address(_feedManager), FEED_ID, 0, DECIMALS, DESCRIPTION, VERSION);
    }

    function test_RevertWhen_OutputDecimalsTooLarge_Initialize() public {
        vm.expectRevert(InvalidDecimals.selector);
        _feedAdapter.initialize(address(_feedManager), FEED_ID, DECIMALS, 19, DESCRIPTION, VERSION);
    }

    function test_RevertWhen_OutputDecimalsZero_Initialize() public {
        vm.expectRevert(InvalidDecimals.selector);
        _feedAdapter.initialize(address(_feedManager), FEED_ID, DECIMALS, 0, DESCRIPTION, VERSION);
    }

    function test_ValidDecimals_Initialize() public {
        _feedAdapter.initialize(address(_feedManager), FEED_ID, 18, 18, DESCRIPTION, VERSION);
        assertEq(_feedAdapter.decimals(), 18);
    }
}

contract EOFeedAdapterTest is EOFeedAdapterTestUninitialized {
    function setUp() public virtual override {
        super.setUp();
        _feedAdapter.initialize(address(_feedManager), FEED_ID, DECIMALS, DECIMALS, DESCRIPTION, VERSION);
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

    function test_LatestAnswerWithDecimals() public {
        EOFeedAdapter feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));
        feedAdapter.initialize(address(_feedManager), FEED_ID, DECIMALS, uint8(4), DESCRIPTION, VERSION);
        assertEq(feedAdapter.latestAnswer(), int256(RATE1 / 10 ** (DECIMALS - 4)));
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

    function test_InputDecimalsBiggerThanOutput_LatestRoundData() public {
        EOFeedAdapter feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));
        feedAdapter.initialize(address(_feedManager), FEED_ID, 10, 8, DESCRIPTION, VERSION);
        _updatePriceFeed(FEED_ID, 1_234_567_890, block.timestamp);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feedAdapter.latestRoundData();
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, 12_345_678);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function test_OutputDecimalsBiggerThanInput_LatestRoundData() public {
        EOFeedAdapter feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));
        feedAdapter.initialize(address(_feedManager), FEED_ID, 8, 10, DESCRIPTION, VERSION);
        _updatePriceFeed(FEED_ID, 12_345_678, block.timestamp);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feedAdapter.latestRoundData();
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, 1_234_567_800);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function test_InputDecimalsBiggerThanOutput_GetRoundData() public {
        EOFeedAdapter feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));
        feedAdapter.initialize(address(_feedManager), FEED_ID, 10, 8, DESCRIPTION, VERSION);
        _updatePriceFeed(FEED_ID, 1_234_567_890, block.timestamp);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feedAdapter.getRoundData(1);
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, 12_345_678);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function test_OutputDecimalsBiggerThanInput_GetRoundData() public {
        EOFeedAdapter feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));
        feedAdapter.initialize(address(_feedManager), FEED_ID, 8, 10, DESCRIPTION, VERSION);
        _updatePriceFeed(FEED_ID, 12_345_678, block.timestamp);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            feedAdapter.getRoundData(1);
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, 1_234_567_800);
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function test_InputDecimalsBiggerThanOutput_LatestAnswer() public {
        EOFeedAdapter feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));
        feedAdapter.initialize(address(_feedManager), FEED_ID, 10, 8, DESCRIPTION, VERSION);
        _updatePriceFeed(FEED_ID, 1_234_567_890, block.timestamp);

        assertEq(feedAdapter.latestAnswer(), 12_345_678);
    }

    function test_OutputDecimalsBiggerThanInput_LatestAnswer() public {
        EOFeedAdapter feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));
        feedAdapter.initialize(address(_feedManager), FEED_ID, 8, 10, DESCRIPTION, VERSION);
        _updatePriceFeed(FEED_ID, 12_345_678, block.timestamp);

        assertEq(feedAdapter.latestAnswer(), 1_234_567_800);
    }

    function test_InputDecimalsBiggerThanOutput_GetAnswer() public {
        EOFeedAdapter feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));
        feedAdapter.initialize(address(_feedManager), FEED_ID, 10, 8, DESCRIPTION, VERSION);
        _updatePriceFeed(FEED_ID, 1_234_567_890, block.timestamp);

        assertEq(feedAdapter.getAnswer(1), 12_345_678);
    }

    function test_OutputDecimalsBiggerThanInput_GetAnswer() public {
        EOFeedAdapter feedAdapter = EOFeedAdapter(Upgrades.deployTransparentProxy("EOFeedAdapter.sol", proxyAdmin, ""));
        feedAdapter.initialize(address(_feedManager), FEED_ID, 8, 10, DESCRIPTION, VERSION);
        _updatePriceFeed(FEED_ID, 12_345_678, block.timestamp);

        assertEq(feedAdapter.getAnswer(1), 1_234_567_800);
    }
}

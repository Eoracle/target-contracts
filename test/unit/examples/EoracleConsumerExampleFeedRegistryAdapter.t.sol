// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { EOFeed } from "../../../src/adapters/EOFeed.sol";
import { EOFeedRegistryAdapter } from "../../../src/adapters/EOFeedRegistryAdapter.sol";
import { EoracleConsumerExampleFeedRegistryAdapter } from
    "../../../src/examples/EoracleConsumerExampleFeedRegistryAdapter.sol";
import { EoracleConsumerExampleFeed } from "../../../src/examples/EoracleConsumerExampleFeed.sol";
import { MockEOFeedRegistry } from "../../mock/MockEOFeedRegistry.sol";
import { IEOFeed } from "../../../src/adapters/interfaces/IEOFeed.sol";
import { IEOFeedVerifier } from "../../../src/interfaces/IEOFeedVerifier.sol";
// solhint-disable ordering
import { ICheckpointManager } from "../../../src/interfaces/ICheckpointManager.sol";
import { Denominations } from "../../../src/libraries/Denominations.sol";

contract EoracleConsumerExampleFeedRegistryAdapterTest is Test {
    EOFeed public feedImpl;
    MockEOFeedRegistry public feedRegistry;
    EOFeedRegistryAdapter public feedRegistryAdapter;
    EoracleConsumerExampleFeedRegistryAdapter public consumerExampleFeedRegistryAdapter;
    EoracleConsumerExampleFeed public consumerExampleFeed;
    address internal _owner;
    uint8 internal _decimals = 8;
    uint16 internal _pairSymbol = 1;
    string internal _description = "ETH/USD";
    uint256 internal _version = 1;
    uint256 internal constant RATE1 = 100_000_000;
    uint256 internal constant RATE2 = 200_000_000;

    function setUp() public virtual {
        _owner = makeAddr("_owner");

        feedRegistry = new MockEOFeedRegistry();
        feedImpl = new EOFeed();
        feedRegistryAdapter = new EOFeedRegistryAdapter();

        feedRegistryAdapter.initialize(address(feedRegistry), address(feedImpl), _owner);

        vm.prank(_owner);
        IEOFeed feed = feedRegistryAdapter.deployEOFeed(
            Denominations.ETH, Denominations.USD, _pairSymbol, _description, _decimals, _version
        );

        consumerExampleFeedRegistryAdapter = new EoracleConsumerExampleFeedRegistryAdapter(address(feedRegistryAdapter));
        consumerExampleFeed = new EoracleConsumerExampleFeed(address(feed));

        _updatePriceFeed(_pairSymbol, RATE1, block.timestamp);
    }

    function test_SetGetFeedRegistryAdapter() public {
        address newFeedRegistryAdapter = makeAddr("_feedRegistry");
        consumerExampleFeedRegistryAdapter.setFeedRegistryAdapter(newFeedRegistryAdapter);
        assertEq(address(consumerExampleFeedRegistryAdapter.getFeedRegistryAdapter()), newFeedRegistryAdapter);
    }

    function test_GetEthUsdPrice() public view {
        int256 price = consumerExampleFeedRegistryAdapter.getEthUsdPrice();
        assertEq(price, int256(RATE1));
    }

    function test_GetPrice() public view {
        int256 price = consumerExampleFeedRegistryAdapter.getPrice(Denominations.ETH, Denominations.USD);
        assertEq(price, int256(RATE1));
    }

    function test_UpdatePriceFeed() public {
        _updatePriceFeed(_pairSymbol, RATE2, block.timestamp);
        assertEq(consumerExampleFeedRegistryAdapter.getPrice(Denominations.ETH, Denominations.USD), int256(RATE2));
        assertEq(consumerExampleFeedRegistryAdapter.getEthUsdPrice(), int256(RATE2));
    }

    function _updatePriceFeed(uint16 pairSymbol, uint256 rate, uint256 timestamp) internal {
        IEOFeedVerifier.LeafInput memory input;
        input.unhashedLeaf = abi.encode(pairSymbol, rate, timestamp);
        feedRegistry.updatePriceFeed(
            input,
            ICheckpointManager.CheckpointMetadata({
                currentValidatorSetHash: bytes32(0),
                blockHash: bytes32(0),
                blockRound: 0
            }),
            ICheckpointManager.Checkpoint({ blockNumber: 0, epoch: 0, eventRoot: bytes32(0) }),
            [uint256(0), uint256(0)],
            bytes("0")
        );
    }
}

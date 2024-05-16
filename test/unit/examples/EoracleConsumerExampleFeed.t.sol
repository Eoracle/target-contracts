// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { EOFeed } from "../../../src/adapters/EOFeed.sol";
import { EOFeedRegistryAdapter } from "../../../src/adapters/EOFeedRegistryAdapter.sol";
import { EoracleConsumerExampleFeed } from "../../../src/examples/EoracleConsumerExampleFeed.sol";
import { MockEOFeedRegistry } from "../../mock/MockEOFeedRegistry.sol";
import { IEOFeedVerifier } from "../../../src/interfaces/IEOFeedVerifier.sol";
import { IEOFeed } from "../../../src/adapters/interfaces/IEOFeed.sol";
// solhint-disable ordering
import { Denominations } from "../../../src/libraries/Denominations.sol";

contract EoracleConsumerExampleFeedTest is Test {
    EOFeed public feedImpl;
    MockEOFeedRegistry public feedRegistry;
    EOFeedRegistryAdapter public feedRegistryAdapter;
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

        consumerExampleFeed = new EoracleConsumerExampleFeed(address(feed));

        _updatePriceFeed(_pairSymbol, RATE1, block.timestamp);
    }

    function test_SetGetFeed() public {
        address newFeed = makeAddr("_feed");
        consumerExampleFeed.setFeed(newFeed);
        assertEq(address(consumerExampleFeed.getFeed()), newFeed);
    }

    function test_GetPrice() public view {
        int256 price = consumerExampleFeed.getPrice();
        assertEq(price, int256(RATE1));
    }

    function test_UpdatePriceFeed() public {
        _updatePriceFeed(_pairSymbol, RATE2, block.timestamp);
        int256 price = consumerExampleFeed.getPrice();
        assertEq(price, int256(RATE2));
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

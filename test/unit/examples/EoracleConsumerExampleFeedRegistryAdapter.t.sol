// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { EOFeedAdapter } from "../../../src/adapters/EOFeedAdapter.sol";
import { EOFeedRegistryAdapter } from "../../../src/adapters/EOFeedRegistryAdapter.sol";
import { EoracleConsumerExampleFeedRegistryAdapter } from
    "../../../src/examples/EoracleConsumerExampleFeedRegistryAdapter.sol";
import { EoracleConsumerExampleFeedAdapter } from "../../../src/examples/EoracleConsumerExampleFeedAdapter.sol";
import { MockEOFeedManager } from "../../mock/MockEOFeedManager.sol";
import { IEOFeedAdapter } from "../../../src/adapters/interfaces/IEOFeedAdapter.sol";
import { IEOFeedVerifier } from "../../../src/interfaces/IEOFeedVerifier.sol";
// solhint-disable ordering
import { Denominations } from "../../../src/libraries/Denominations.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract EoracleConsumerExampleFeedRegistryAdapterTest is Test {
    uint8 public constant DECIMALS = 8;
    uint16 public constant FEED_ID = 1;
    string public constant DESCRIPTION = "ETH/USD";
    uint256 public constant VERSION = 1;
    uint256 public constant RATE1 = 100_000_000;
    uint256 public constant RATE2 = 200_000_000;
    address public proxyAdmin = makeAddr("proxyAdmin");

    EOFeedAdapter internal _feedAdapterImplementation;
    MockEOFeedManager internal _feedManager;
    EOFeedRegistryAdapter internal _feedRegistryAdapter;
    EoracleConsumerExampleFeedRegistryAdapter internal _consumerExampleFeedRegistryAdapter;
    EoracleConsumerExampleFeedAdapter internal _consumerExampleFeed;
    address internal _owner;

    function setUp() public virtual {
        _owner = makeAddr("_owner");

        _feedManager = new MockEOFeedManager();
        _feedAdapterImplementation = new EOFeedAdapter();
        _feedRegistryAdapter =
            EOFeedRegistryAdapter(Upgrades.deployTransparentProxy("EOFeedRegistryAdapter.sol", proxyAdmin, ""));

        _feedRegistryAdapter.initialize(address(_feedManager), address(_feedAdapterImplementation), _owner);

        vm.prank(_owner);
        IEOFeedAdapter feedAdapter = _feedRegistryAdapter.deployEOFeedAdapter(
            Denominations.ETH, Denominations.USD, FEED_ID, DESCRIPTION, DECIMALS, DECIMALS, VERSION
        );

        _consumerExampleFeedRegistryAdapter =
            new EoracleConsumerExampleFeedRegistryAdapter(address(_feedRegistryAdapter));
        _consumerExampleFeed = new EoracleConsumerExampleFeedAdapter(address(feedAdapter));

        _updatePriceFeed(FEED_ID, RATE1, block.timestamp);
    }

    function test_SetGetFeedRegistryAdapter() public {
        address newFeedRegistryAdapter = makeAddr("_feedManager");
        _consumerExampleFeedRegistryAdapter.setFeedRegistryAdapter(newFeedRegistryAdapter);
        assertEq(address(_consumerExampleFeedRegistryAdapter.getFeedRegistryAdapter()), newFeedRegistryAdapter);
    }

    function test_GetEthUsdPrice() public view {
        int256 price = _consumerExampleFeedRegistryAdapter.getEthUsdPrice();
        assertEq(price, int256(RATE1));
    }

    function test_GetPrice() public view {
        int256 price = _consumerExampleFeedRegistryAdapter.getPrice(Denominations.ETH, Denominations.USD);
        assertEq(price, int256(RATE1));
    }

    function test_UpdatePriceFeed() public {
        _updatePriceFeed(FEED_ID, RATE2, block.timestamp);
        assertEq(_consumerExampleFeedRegistryAdapter.getPrice(Denominations.ETH, Denominations.USD), int256(RATE2));
        assertEq(_consumerExampleFeedRegistryAdapter.getEthUsdPrice(), int256(RATE2));
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

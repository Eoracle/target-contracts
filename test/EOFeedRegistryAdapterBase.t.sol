// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { EOFeed } from "../src/adapters/EOFeed.sol";
import { IEOFeed } from "../src/adapters/interfaces/IEOFeed.sol";
import { MockEOFeedRegistry } from "./mock/MockEOFeedRegistry.sol";
import { IEOFeedRegistry } from "../src/interfaces/IEOFeedRegistry.sol";
import { EOFeedRegistryAdapterBase } from "../src/adapters/EOFeedRegistryAdapterBase.sol";
//beacon
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// solhint-disable ordering
// solhint-disable no-empty-blocks
abstract contract EOFeedRegistryAdapterBaseTest is Test {
    EOFeed public feedImpl;
    IEOFeedRegistry public feedRegistry;
    EOFeedRegistryAdapterBase public feedRegistryAdapter;
    address internal _notOwner;
    uint8 internal _decimals = 8;
    string internal _description = "ETH/USD";
    address internal _baseAddress;
    address internal _quoteAddress;
    string internal _description2 = "BTC/USD";
    address internal _base2Address;
    address internal _quote2Address;
    uint256 internal _version = 1;
    uint256 internal _lastTimestamp;
    uint256 internal constant RATE1 = 100_000_000;
    uint256 internal constant RATE2 = 200_000_000;
    uint256 internal _test;

    event FeedRegistrySet(address indexed feedRegistry);
    event FeedDeployed(string indexed pairSymbol, address indexed feed);
    event PairSymbolAdded(address indexed base, address indexed quote, string indexed pairSymbol);

    function setUp() public virtual {
        _test = 10;
        _notOwner = makeAddr("_notOwner");

        feedRegistry = new MockEOFeedRegistry();
        feedImpl = new EOFeed();
        feedRegistryAdapter = _deployAdapter();
        feedRegistryAdapter.initialize(address(feedRegistry), address(feedImpl));

        _baseAddress = makeAddr("base");
        _quoteAddress = makeAddr("quote");
        _base2Address = makeAddr("base2");
        _quote2Address = makeAddr("quote2");
    }

    function test_Initialized() public view {
        assertEq(address(feedRegistryAdapter.getFeedRegistry()), address(feedRegistry));
        assertEq(address(feedRegistryAdapter.owner()), address(this));
    }

    function test_FactoryInitialized() public view virtual { }

    function test_SetFeedRegistry() public {
        IEOFeedRegistry newFeedRegistry = new MockEOFeedRegistry();
        vm.expectEmit();
        emit FeedRegistrySet(address(newFeedRegistry));
        feedRegistryAdapter.setFeedRegistry(address(newFeedRegistry));
        assertEq(address(feedRegistryAdapter.getFeedRegistry()), address(newFeedRegistry));
    }

    function test_RevertWhen_setFeedRegistry_NotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(_notOwner))
        );
        vm.prank(_notOwner);
        feedRegistryAdapter.setFeedRegistry(address(this));
    }

    function test_DeployFeed() public {
        address unknownExpepctedFeedAddress = address(0);
        // second topic is false (don't check) as we deploy without predictable address feature, create, not create2
        vm.expectEmit(true, false, false, false);
        emit FeedDeployed(_description, unknownExpepctedFeedAddress);

        vm.expectEmit();
        emit PairSymbolAdded(_baseAddress, _quoteAddress, _description);

        IEOFeed feed = _deployEOFeed(_baseAddress, _quoteAddress, _description, _decimals, _version);

        assertEq(address(feedRegistryAdapter.getFeed(_baseAddress, _quoteAddress)), address(feed));
        assertEq(address(feedRegistryAdapter.getFeedByPairSymbol(_description)), address(feed));
        assertTrue(feedRegistryAdapter.isFeedEnabled(address(feed)));
        assertEq(feedRegistryAdapter.decimals(_baseAddress, _quoteAddress), _decimals);
        assertEq(feedRegistryAdapter.description(_baseAddress, _quoteAddress), _description);
        assertEq(feedRegistryAdapter.version(_baseAddress, _quoteAddress), _version);

        assertEq(feed.decimals(), _decimals);
        assertEq(feed.description(), _description);
        assertEq(feed.version(), _version);
    }

    function test_DeployFeed2() public {
        _deployEOFeed(_baseAddress, _quoteAddress, _description, _decimals, _version);
        IEOFeed feed2 = _deployEOFeed(_base2Address, _quote2Address, _description2, _decimals, _version);

        assertEq(address(feedRegistryAdapter.getFeed(_base2Address, _quote2Address)), address(feed2));
        assertTrue(feedRegistryAdapter.isFeedEnabled(address(feed2)));
        assertEq(feedRegistryAdapter.decimals(_base2Address, _quote2Address), _decimals);
        assertEq(feedRegistryAdapter.description(_base2Address, _quote2Address), _description2);
        assertEq(feedRegistryAdapter.version(_base2Address, _quote2Address), _version);

        assertEq(feed2.decimals(), _decimals);
        assertEq(feed2.description(), _description2);
        assertEq(feed2.version(), _version);
    }

    function test_RevertWhen_DeployFeed_ExistingFeed() public {
        _deployEOFeed(_baseAddress, _quoteAddress, _description, _decimals, _version);
        vm.expectRevert(EOFeedRegistryAdapterBase.FeedAlreadyExists.selector);
        _deployEOFeed(_base2Address, _quote2Address, _description, _decimals, _version);
    }

    function test_RevertWhen_DeployFeed_ExistingPair() public {
        _deployEOFeed(_baseAddress, _quoteAddress, _description, _decimals, _version);
        vm.expectRevert(EOFeedRegistryAdapterBase.BaseQuotePairExists.selector);
        _deployEOFeed(_baseAddress, _quoteAddress, _description2, _decimals, _version);
    }

    function test_RevertWhen_DeployFeed_NotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(_notOwner))
        );
        vm.prank(_notOwner);
        _deployEOFeed(_baseAddress, _quoteAddress, _description, _decimals, _version);
    }

    function test_LatestAnswer() public {
        _deployEOFeed(_baseAddress, _quoteAddress, _description, _decimals, _version);
        feedRegistry.updatePriceFeed(_description, RATE1, block.timestamp, "");
        assertEq(feedRegistryAdapter.latestAnswer(_baseAddress, _quoteAddress), int256(RATE1));
    }

    function test_LatestTimestamp() public {
        _deployEOFeed(_baseAddress, _quoteAddress, _description, _decimals, _version);
        feedRegistry.updatePriceFeed(_description, RATE1, block.timestamp, "");
        assertEq(feedRegistryAdapter.latestTimestamp(_baseAddress, _quoteAddress), block.timestamp);
    }

    function test_GetRoundFeed() public {
        // solhint-disable-next-line func-named-parameters
        IEOFeed feed = _deployEOFeed(_baseAddress, _quoteAddress, _description, _decimals, _version);
        assertEq(address(feedRegistryAdapter.getRoundFeed(_baseAddress, _quoteAddress, 1)), address(feed));
    }

    function _deployEOFeed(
        address base,
        address quote,
        string memory description,
        uint8 decimals,
        uint256 version
    )
        internal
        returns (IEOFeed)
    {
        // solhint-disable-next-line func-named-parameters
        IEOFeed feed = feedRegistryAdapter.deployEOFeed(base, quote, description, description, decimals, version);
        return feed;
    }

    function _deployAdapter() internal virtual returns (EOFeedRegistryAdapterBase) { }
}

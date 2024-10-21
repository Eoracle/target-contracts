// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { EOFeedAdapter } from "../../../src/adapters/EOFeedAdapter.sol";
import { IEOFeedAdapter } from "../../../src/adapters/interfaces/IEOFeedAdapter.sol";
import { EOFeedRegistryAdapterBase } from "../../../src/adapters/EOFeedRegistryAdapterBase.sol";
import { MockEOFeedManager } from "../../mock/MockEOFeedManager.sol";
import { IEOFeedManager } from "../../../src/interfaces/IEOFeedManager.sol";
import { EOFeedRegistryAdapterBase } from "../../../src/adapters/EOFeedRegistryAdapterBase.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IEOFeedVerifier } from "../../../src/interfaces/IEOFeedVerifier.sol";
import { FeedAlreadyExists, BaseQuotePairExists, FeedNotSupported } from "../../../src/interfaces/Errors.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Options } from "openzeppelin-foundry-upgrades/Options.sol";

// solhint-disable ordering
// solhint-disable no-empty-blocks
abstract contract EOFeedRegistryAdapterBaseTest is Test {
    uint16 public constant FEED_ID1 = 1;
    uint16 public constant FEED_ID2 = 2;
    string public constant DESCRIPTION1 = "ETH/USD";
    string public constant DESCRIPTION2 = "BTC/USD";
    uint256 public constant RATE1 = 100_000_000;
    uint256 public constant RATE2 = 200_000_000;
    uint8 public constant DECIMALS = 8;
    uint256 public constant VERSION = 1;

    IEOFeedManager internal _feedManager;
    EOFeedRegistryAdapterBase internal _feedRegistryAdapter;
    EOFeedAdapter internal _feedAdapterImplementation;
    address internal _proxyAdmin = makeAddr("proxyAdmin");
    address internal _notOwner = makeAddr("_notOwner");
    address internal _base1Address;
    address internal _quote1Address;
    address internal _base2Address;
    address internal _quote2Address;
    uint256 internal _lastTimestamp;
    uint256 internal _lastBlockNumber;

    event FeedManagerSet(address indexed _feedManager);
    event FeedAdapterDeployed(uint16 indexed feedId, address indexed feedAdapter, address base, address quote);

    function setUp() public virtual {
        _feedManager = new MockEOFeedManager();
        Options memory opts;
        _feedAdapterImplementation = EOFeedAdapter(Upgrades.deployImplementation("EOFeedAdapter.sol", opts));

        _feedRegistryAdapter = _deployAdapter();
        _feedRegistryAdapter.initialize(address(_feedManager), address(_feedAdapterImplementation), address(this));

        _base1Address = makeAddr("base");
        _quote1Address = makeAddr("quote");
        _base2Address = makeAddr("base2");
        _quote2Address = makeAddr("quote2");
        _lastBlockNumber = block.number;
    }

    function test_Initialized() public view {
        assertEq(address(_feedRegistryAdapter.getFeedManager()), address(_feedManager));
        assertEq(address(_feedRegistryAdapter.owner()), address(this));
    }

    function test_FactoryInitialized() public view virtual { }

    function test_SetFeedManager() public {
        IEOFeedManager newFeedManager = new MockEOFeedManager();
        vm.expectEmit();
        emit FeedManagerSet(address(newFeedManager));
        _feedRegistryAdapter.setFeedManager(address(newFeedManager));
        assertEq(address(_feedRegistryAdapter.getFeedManager()), address(newFeedManager));
    }

    function test_RevertWhen_setFeedManager_NotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(_notOwner))
        );
        vm.prank(_notOwner);
        _feedRegistryAdapter.setFeedManager(address(this));
    }

    function test_DeployFeedAdapter() public {
        address unknownExpectedFeedAddress = address(0);
        // second topic is false (don't check) as we deploy without predictable address feature, create, not create2
        vm.expectEmit(true, false, false, false);
        emit FeedAdapterDeployed(FEED_ID1, unknownExpectedFeedAddress, _base1Address, _quote1Address);

        IEOFeedAdapter feedAdapter =
            _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);

        assertEq(address(_feedRegistryAdapter.getFeed(_base1Address, _quote1Address)), address(feedAdapter));
        assertEq(address(_feedRegistryAdapter.getFeedById(FEED_ID1)), address(feedAdapter));
        assertTrue(_feedRegistryAdapter.isFeedEnabled(address(feedAdapter)));
        assertEq(_feedRegistryAdapter.decimals(_base1Address, _quote1Address), DECIMALS);
        assertEq(_feedRegistryAdapter.description(_base1Address, _quote1Address), DESCRIPTION1);
        assertEq(_feedRegistryAdapter.version(_base1Address, _quote1Address), VERSION);

        assertEq(feedAdapter.decimals(), DECIMALS);
        assertEq(feedAdapter.description(), DESCRIPTION1);
        assertEq(feedAdapter.version(), VERSION);
    }

    function test_DeployFeed2() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        IEOFeedAdapter feed2 =
            _deployEOFeedAdapter(_base2Address, _quote2Address, FEED_ID2, DESCRIPTION2, DECIMALS, DECIMALS, VERSION);

        assertEq(address(_feedRegistryAdapter.getFeed(_base2Address, _quote2Address)), address(feed2));
        assertTrue(_feedRegistryAdapter.isFeedEnabled(address(feed2)));
        assertEq(_feedRegistryAdapter.decimals(_base2Address, _quote2Address), DECIMALS);
        assertEq(_feedRegistryAdapter.description(_base2Address, _quote2Address), DESCRIPTION2);
        assertEq(_feedRegistryAdapter.version(_base2Address, _quote2Address), VERSION);

        assertEq(feed2.decimals(), DECIMALS);
        assertEq(feed2.description(), DESCRIPTION2);
        assertEq(feed2.version(), VERSION);
    }

    function test_RevertWhen_DeployFeedAdapter_ExistingFeed() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        vm.expectRevert(FeedAlreadyExists.selector);
        _deployEOFeedAdapter(_base2Address, _quote2Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
    }

    function test_RevertWhen_DeployFeedAdapter_ExistingPair() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        vm.expectRevert(BaseQuotePairExists.selector);
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID2, DESCRIPTION2, DECIMALS, DECIMALS, VERSION);
    }

    function test_RevertWhen_DeployFeedAdapter_NotSupportedFeed() public {
        uint16 feedId = MockEOFeedManager(address(_feedManager)).NOT_SUPPORTED_FEED();
        vm.expectRevert(abi.encodeWithSelector(FeedNotSupported.selector, feedId));
        _deployEOFeedAdapter(_base1Address, _quote1Address, feedId, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
    }

    function test_RevertWhen_DeployFeedAdapter_NotOwner() public {
        vm.expectRevert(
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(_notOwner))
        );
        vm.prank(_notOwner);
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
    }

    function test_Decimals() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        assertEq(_feedRegistryAdapter.decimals(_base1Address, _quote1Address), DECIMALS);
    }

    function test_Description() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        assertEq(_feedRegistryAdapter.description(_base1Address, _quote1Address), DESCRIPTION1);
    }

    function test_Version() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        assertEq(_feedRegistryAdapter.version(_base1Address, _quote1Address), VERSION);
    }

    function test_LatestRoundData() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        _updatePriceFeed(FEED_ID1, RATE1, block.timestamp);
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            _feedRegistryAdapter.latestRoundData(_base1Address, _quote1Address);
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, int256(RATE1));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function test_GetRoundData() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        _updatePriceFeed(FEED_ID1, RATE1, block.timestamp);
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            _feedRegistryAdapter.getRoundData(_base1Address, _quote1Address, 1);
        assertEq(roundId, _lastBlockNumber);
        assertEq(answer, int256(RATE1));
        assertEq(startedAt, block.timestamp);
        assertEq(updatedAt, block.timestamp);
        assertEq(answeredInRound, _lastBlockNumber);
    }

    function test_LatestAnswer() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        _updatePriceFeed(FEED_ID1, RATE1, block.timestamp);
        assertEq(_feedRegistryAdapter.latestAnswer(_base1Address, _quote1Address), int256(RATE1));
    }

    function test_LatestTimestamp() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        _updatePriceFeed(FEED_ID1, RATE1, block.timestamp);
        assertEq(_feedRegistryAdapter.latestTimestamp(_base1Address, _quote1Address), block.timestamp);
    }

    function test_LatestRound() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        _updatePriceFeed(FEED_ID1, RATE1, block.timestamp);
        assertEq(_feedRegistryAdapter.latestRound(_base1Address, _quote1Address), _lastBlockNumber);
    }

    function test_GetAnswer() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        _updatePriceFeed(FEED_ID1, RATE1, block.timestamp);
        assertEq(_feedRegistryAdapter.getAnswer(_base1Address, _quote1Address, 1), int256(RATE1));
    }

    function test_GetTimestamp() public {
        _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        _updatePriceFeed(FEED_ID1, RATE1, block.timestamp);
        assertEq(_feedRegistryAdapter.getTimestamp(_base1Address, _quote1Address, 1), block.timestamp);
    }

    function test_IsFeedEnabled() public {
        IEOFeedAdapter feedAdapter =
            _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        assertTrue(_feedRegistryAdapter.isFeedEnabled(address(feedAdapter)));
    }

    function test_GetRoundFeed() public {
        // solhint-disable-next-line func-named-parameters
        IEOFeedAdapter feedAdapter =
            _deployEOFeedAdapter(_base1Address, _quote1Address, FEED_ID1, DESCRIPTION1, DECIMALS, DECIMALS, VERSION);
        assertEq(
            address(_feedRegistryAdapter.getRoundFeed(_base1Address, _quote1Address, uint80(_lastBlockNumber))),
            address(feedAdapter)
        );
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
            bytes("1")
        );
    }

    function _deployEOFeedAdapter(
        address base,
        address quote,
        uint16 feedId,
        string memory description,
        uint8 inputDecimals,
        uint8 outputDecimals,
        uint256 version
    )
        internal
        returns (IEOFeedAdapter)
    {
        // solhint-disable-next-line func-named-parameters
        IEOFeedAdapter feedAdapter = _feedRegistryAdapter.deployEOFeedAdapter(
            base, quote, feedId, description, inputDecimals, outputDecimals, version
        );
        return feedAdapter;
    }

    function _deployAdapter() internal virtual returns (EOFeedRegistryAdapterBase) { }
}

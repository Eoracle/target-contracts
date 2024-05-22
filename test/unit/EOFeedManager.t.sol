// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Test } from "forge-std/Test.sol";
import { Utils } from "../utils/Utils.sol";
import { IEOFeedManager } from "../../src/interfaces/IEOFeedManager.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { EOFeedManager } from "../../src/EOFeedManager.sol";
import { MockFeedVerifier } from "../mock/MockFeedVerifier.sol";
import {
    CallerIsNotWhitelisted,
    FeedNotSupported,
    MissingLeafInputs,
    BlockNumberAlreadyProcessed
} from "../../src/interfaces/Errors.sol";

contract EOFeedManagerTests is Test, Utils {
    EOFeedManager private registry;
    IEOFeedVerifier private verifier;
    address private publisher = makeAddr("publisher");
    address private owner = makeAddr("owner");
    address private notOwner = makeAddr("notOwner");
    uint16 private feedId = 1;
    uint256 private rate = 1_000_000;
    uint256 private timestamp = 9_999_999_999;
    bytes32 private blockHash = keccak256("BLOCK_HASH");
    bytes32 private eventRoot = keccak256("EVENT_ROOT");
    bytes32 private validatorSetHash = keccak256("VALIDATOR_SET_HASH");
    uint256 private blockRound = 0;
    uint256 private epochNumber = 1;
    uint256 private blockNumber = 1;

    event RateUpdated(uint16 feedId, uint256 rate, uint256 timestamp);

    function setUp() public {
        verifier = new MockFeedVerifier();
        registry = new EOFeedManager();
        vm.startPrank(owner);
        registry.initialize(verifier, owner);
        vm.stopPrank();
    }

    function test_RevertWhen_whitelistPublishersNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, notOwner));
        _whitelistPublisher(notOwner, publisher);
    }

    function test_whitelistPublishers() public {
        address[] memory publishers = new address[](5);
        bool[] memory isWhitelisted = new bool[](5);
        for (uint256 i = 0; i < 5; i++) {
            publishers[i] = makeAddr(string(abi.encode("publisher_", uint256(i))));
            isWhitelisted[i] = true;
        }
        vm.prank(owner);
        registry.whitelistPublishers(publishers, isWhitelisted);
        for (uint256 i = 0; i < 5; i++) {
            assert(registry.isWhitelistedPublisher(publishers[i]));
        }
        assertEq(registry.isWhitelistedPublisher(notOwner), false);
    }

    function test_RevertWhen_setSupportedFeedsNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, notOwner));
        _setSupportedFeed(notOwner, feedId);
    }

    function test_setSupportedFeeds() public {
        uint16[] memory feedIds = new uint16[](5);
        bool[] memory isSupported = new bool[](5);
        for (uint256 i = 0; i < 5; i++) {
            feedIds[i] = uint16(i);
            isSupported[i] = true;
        }
        vm.prank(owner);
        registry.setSupportedFeeds(feedIds, isSupported);
        for (uint256 i = 0; i < 5; i++) {
            assert(registry.isSupportedFeed(feedIds[i]));
        }
        assertEq(registry.isSupportedFeed(6), false);
    }

    function test_RevertWhen_updatePriceFeedNotWhitelisted() public {
        bytes memory ratesData = abi.encode(feedId, rate, timestamp);
        bytes memory unhashedLeaf = abi.encode(1, address(0), address(0), ratesData);

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            blockNumber: blockNumber,
            epoch: epochNumber,
            eventRoot: eventRoot,
            blockHash: blockHash,
            blockRound: blockRound
        });
        uint256[2] memory signature = [uint256(1), uint256(2)];
        bytes memory bitmap = bytes("1");
        IEOFeedVerifier.LeafInput memory input =
            IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaf, leafIndex: 1, proof: new bytes32[](0) });
        vm.expectRevert(abi.encodeWithSelector(CallerIsNotWhitelisted.selector, address(this)));
        registry.updatePriceFeed(input, checkpoint, signature, bitmap);
    }

    function test_RevertWhen_updatePriceFeedFeedNotSupported() public {
        bytes memory ratesData = abi.encode(feedId, rate, timestamp);
        bytes memory unhashedLeaf = abi.encode(1, address(0), address(0), ratesData);

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            blockNumber: blockNumber,
            epoch: epochNumber,
            eventRoot: eventRoot,
            blockHash: blockHash,
            blockRound: blockRound
        });
        uint256[2] memory signature = [uint256(1), uint256(2)];
        bytes memory bitmap = bytes("1");
        IEOFeedVerifier.LeafInput memory input =
            IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaf, leafIndex: 1, proof: new bytes32[](0) });

        _whitelistPublisher(owner, publisher);
        vm.expectRevert(abi.encodeWithSelector(FeedNotSupported.selector, feedId));
        vm.prank(publisher);
        registry.updatePriceFeed(input, checkpoint, signature, bitmap);
    }

    function test_updatePriceFeed() public {
        bytes memory ratesData = abi.encode(feedId, rate, timestamp);
        bytes memory unhashedLeaf = abi.encode(1, address(0), address(0), ratesData);

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            blockNumber: blockNumber,
            epoch: epochNumber,
            eventRoot: eventRoot,
            blockHash: blockHash,
            blockRound: blockRound
        });
        uint256[2] memory signature = [uint256(1), uint256(2)];
        bytes memory bitmap = bytes("1");
        IEOFeedVerifier.LeafInput memory input =
            IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaf, leafIndex: 1, proof: new bytes32[](0) });
        _whitelistPublisher(owner, publisher);
        _setSupportedFeed(owner, feedId);
        vm.expectEmit(true, true, true, true);
        emit RateUpdated(feedId, rate, timestamp);
        vm.prank(publisher);
        registry.updatePriceFeed(input, checkpoint, signature, bitmap);
        IEOFeedManager.PriceFeed memory feedAdapter = registry.getLatestPriceFeed(1);
        assertEq(feedAdapter.value, rate);
    }

    function test_RevertWhen_BlockNumberAlreadyProcessed_updatePriceFeed() public {
        bytes memory ratesData = abi.encode(feedId, rate, timestamp);
        bytes memory unhashedLeaf = abi.encode(1, address(0), address(0), ratesData);

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            blockNumber: blockNumber,
            epoch: epochNumber,
            eventRoot: eventRoot,
            blockHash: blockHash,
            blockRound: blockRound
        });
        uint256[2] memory signature = [uint256(1), uint256(2)];
        bytes memory bitmap = bytes("1");
        IEOFeedVerifier.LeafInput memory input =
            IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaf, leafIndex: 1, proof: new bytes32[](0) });
        _whitelistPublisher(owner, publisher);
        _setSupportedFeed(owner, feedId);
        vm.startPrank(publisher);
        registry.updatePriceFeed(input, checkpoint, signature, bitmap);
        checkpoint.blockNumber--;
        vm.expectRevert(abi.encodeWithSelector(BlockNumberAlreadyProcessed.selector));
        registry.updatePriceFeed(input, checkpoint, signature, bitmap);
    }

    function test_updatePriceFeeds() public {
        bytes memory ratesData0 = abi.encode(feedId, rate, timestamp);
        bytes memory unhashedLeaf0 = abi.encode(1, address(0), address(0), ratesData0);
        bytes memory ratesData1 = abi.encode(feedId + 1, rate + 1, timestamp + 1);
        bytes memory unhashedLeaf1 = abi.encode(2, address(0), address(0), ratesData1);

        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            blockNumber: blockNumber,
            epoch: epochNumber,
            eventRoot: eventRoot,
            blockHash: blockHash,
            blockRound: blockRound
        });
        uint256[2] memory signature = [uint256(1), uint256(2)];
        bytes memory bitmap = bytes("1");

        IEOFeedVerifier.LeafInput[] memory inputs = new IEOFeedVerifier.LeafInput[](2);
        inputs[0] = IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaf0, leafIndex: 0, proof: new bytes32[](0) });
        inputs[1] = IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaf1, leafIndex: 1, proof: new bytes32[](0) });

        _whitelistPublisher(owner, publisher);
        _setSupportedFeed(owner, feedId);
        _setSupportedFeed(owner, feedId + 1);
        vm.prank(publisher);
        registry.updatePriceFeeds(inputs, checkpoint, signature, bitmap);
        uint16[] memory feedIds = new uint16[](2);
        feedIds[0] = feedId;
        feedIds[1] = feedId + 1;
        IEOFeedManager.PriceFeed[] memory feeds = registry.getLatestPriceFeeds(feedIds);
        assertEq(feeds[0].value, rate);
        assertEq(feeds[1].value, rate + 1);
    }

    function test_RevertWhen_IncorrectInput_updatePriceFeeds() public {
        IEOFeedVerifier.Checkpoint memory checkpoint = IEOFeedVerifier.Checkpoint({
            blockNumber: 0,
            epoch: 0,
            eventRoot: bytes32(0),
            blockHash: bytes32(0x00),
            blockRound: 0
        });
        uint256[2] memory signature = [uint256(0), uint256(0)];
        bytes memory bitmap = bytes("1");

        _whitelistPublisher(owner, publisher);
        vm.startPrank(publisher);

        IEOFeedVerifier.LeafInput[] memory inputs;
        vm.expectRevert(MissingLeafInputs.selector);
        registry.updatePriceFeeds(inputs, checkpoint, signature, bitmap);
    }

    function test_RevertWhen_FeedNotSupported_GetLatestPriceFeed() public {
        vm.expectRevert(abi.encodeWithSelector(FeedNotSupported.selector, 999));
        registry.getLatestPriceFeed(999);
    }

    function _whitelistPublisher(address _executer, address _publisher) private {
        address[] memory publishers = new address[](1);
        bool[] memory isWhitelisted = new bool[](1);
        publishers[0] = _publisher;
        isWhitelisted[0] = true;
        vm.prank(_executer);
        registry.whitelistPublishers(publishers, isWhitelisted);
    }

    function _setSupportedFeed(address _executer, uint16 _feedId) private {
        uint16[] memory feedIds = new uint16[](1);
        bool[] memory isSupported = new bool[](1);
        feedIds[0] = _feedId;
        isSupported[0] = true;
        vm.prank(_executer);
        registry.setSupportedFeeds(feedIds, isSupported);
    }
}
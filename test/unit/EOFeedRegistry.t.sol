// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { Utils } from "../utils/Utils.sol";
import { IEOFeedRegistry } from "../../src/interfaces/IEOFeedRegistry.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { EOFeedRegistry } from "../../src/EOFeedRegistry.sol";
import { EOFeedVerifier } from "../../src/EOFeedVerifier.sol";
import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";
import { MockCheckpointManager } from "../mock/MockCheckpointManager.sol";
import {
    OwnableUnauthorizedAccount,
    CallerIsNotWhitelisted,
    SymbolNotSupported,
    MissingLeafInputs,
    MissingCheckpoint
} from "../../src/interfaces/Errors.sol";

contract EOFeedRegistryTests is Test, Utils {
    EOFeedRegistry private registry;
    EOFeedVerifier private verifier;
    ICheckpointManager private checkpointManager;
    address private publisher = makeAddr("publisher");
    address private owner = makeAddr("owner");
    address private notOwner = makeAddr("notOwner");
    uint16 private symbol = 1;
    uint256 private rate = 1_000_000;
    uint256 private timestamp = 9_999_999_999;
    bytes32 private blockHash = keccak256("BLOCK_HASH");
    bytes32 private eventRoot = keccak256("EVENT_ROOT");
    bytes32 private validatorSetHash = keccak256("VALIDATOR_SET_HASH");
    uint256 private blockRound = 0;
    uint256 private epochNumber = 1;
    uint256 private blockNumber = 1;

    function setUp() public {
        checkpointManager = new MockCheckpointManager();
        verifier = new EOFeedVerifier();
        registry = new EOFeedRegistry();
        vm.startPrank(owner);
        verifier.initialize(checkpointManager, owner);
        registry.initialize(verifier, owner);
        vm.stopPrank();
    }

    function test_whitelistPublishersRevertIfNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, notOwner));
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

    function test_setSupportedSymbolsRevertIfNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(OwnableUnauthorizedAccount.selector, notOwner));
        _setSupportedSymbol(notOwner, symbol);
    }

    function test_setSupportedSymbols() public {
        uint16[] memory symbols = new uint16[](5);
        bool[] memory isSupported = new bool[](5);
        for (uint256 i = 0; i < 5; i++) {
            symbols[i] = uint16(i);
            isSupported[i] = true;
        }
        vm.prank(owner);
        registry.setSupportedSymbols(symbols, isSupported);
        for (uint256 i = 0; i < 5; i++) {
            assert(registry.isSupportedSymbol(symbols[i]));
        }
        assertEq(registry.isSupportedSymbol(6), false);
    }

    function test_updatePriceFeedRevertIfNotWhitelisted() public {
        bytes memory ratesData = abi.encode(symbol, rate, timestamp);
        bytes memory unhashedLeaf = abi.encode(1, address(0), address(0), ratesData);
        bytes memory checkpointData = abi.encode(
            [uint256(1), uint256(2)], // signature
            bytes("1"), // bitmap
            epochNumber,
            blockNumber,
            blockHash,
            blockRound,
            validatorSetHash,
            eventRoot
        );
        IEOFeedVerifier.LeafInput memory input = IEOFeedVerifier.LeafInput({
            unhashedLeaf: unhashedLeaf,
            leafIndex: 1,
            blockNumber: blockNumber,
            proof: new bytes32[](0)
        });
        vm.expectRevert(CallerIsNotWhitelisted.selector);
        registry.updatePriceFeed(input, checkpointData);
    }

    function test_updatePriceFeedRevertIfSymbolNotSupported() public {
        bytes memory ratesData = abi.encode(symbol, rate, timestamp);
        bytes memory unhashedLeaf = abi.encode(1, address(0), address(0), ratesData);
        bytes memory checkpointData = abi.encode(
            [uint256(1), uint256(2)], // signature
            bytes("1"), // bitmap
            epochNumber,
            blockNumber,
            blockHash,
            blockRound,
            validatorSetHash,
            eventRoot
        );
        IEOFeedVerifier.LeafInput memory input = IEOFeedVerifier.LeafInput({
            unhashedLeaf: unhashedLeaf,
            leafIndex: 1,
            blockNumber: blockNumber,
            proof: new bytes32[](0)
        });

        _whitelistPublisher(owner, publisher);
        vm.expectRevert(SymbolNotSupported.selector);
        vm.prank(publisher);
        registry.updatePriceFeed(input, checkpointData);
    }

    function test_updatePriceFeed() public {
        bytes memory ratesData = abi.encode(symbol, rate, timestamp);
        bytes memory unhashedLeaf = abi.encode(1, address(0), address(0), ratesData);

        bytes memory checkpointData = abi.encode(
            [uint256(1), uint256(2)], // signature
            bytes("1"), // bitmap
            epochNumber,
            blockNumber,
            blockHash,
            blockRound,
            validatorSetHash,
            eventRoot
        );
        IEOFeedVerifier.LeafInput memory input = IEOFeedVerifier.LeafInput({
            unhashedLeaf: unhashedLeaf,
            leafIndex: 1,
            blockNumber: blockNumber,
            proof: new bytes32[](0)
        });
        _whitelistPublisher(owner, publisher);
        _setSupportedSymbol(owner, symbol);
        vm.prank(publisher);
        registry.updatePriceFeed(input, checkpointData);
        IEOFeedRegistry.PriceFeed memory feed = registry.getLatestPriceFeed(1);
        assertEq(feed.value, rate);
    }

    function test_updatePriceFeeds() public {
        bytes memory ratesData0 = abi.encode(symbol, rate, timestamp);
        bytes memory unhashedLeaf0 = abi.encode(1, address(0), address(0), ratesData0);
        bytes memory ratesData1 = abi.encode(symbol + 1, rate + 1, timestamp + 1);
        bytes memory unhashedLeaf1 = abi.encode(2, address(0), address(0), ratesData1);

        bytes memory checkpointData = abi.encode(
            [uint256(1), uint256(2)], // signature
            bytes("1"), // bitmap
            epochNumber,
            blockNumber,
            blockHash,
            blockRound,
            validatorSetHash,
            eventRoot
        );
        IEOFeedVerifier.LeafInput[] memory inputs = new IEOFeedVerifier.LeafInput[](2);
        inputs[0] = IEOFeedVerifier.LeafInput({
            unhashedLeaf: unhashedLeaf0,
            leafIndex: 0,
            blockNumber: blockNumber,
            proof: new bytes32[](0)
        });
        inputs[1] = IEOFeedVerifier.LeafInput({
            unhashedLeaf: unhashedLeaf1,
            leafIndex: 1,
            blockNumber: blockNumber,
            proof: new bytes32[](0)
        });

        _whitelistPublisher(owner, publisher);
        _setSupportedSymbol(owner, symbol);
        _setSupportedSymbol(owner, symbol + 1);
        vm.prank(publisher);
        registry.updatePriceFeeds(inputs, checkpointData);
        uint16[] memory symbols = new uint16[](2);
        symbols[0] = symbol;
        symbols[1] = symbol + 1;
        IEOFeedRegistry.PriceFeed[] memory feeds = registry.getLatestPriceFeeds(symbols);
        assertEq(feeds[0].value, rate);
        assertEq(feeds[1].value, rate + 1);
    }

    function test_RevertWhen_IncorrectInput_updatePriceFeeds() public {
        _whitelistPublisher(owner, publisher);
        vm.startPrank(publisher);
        bytes memory checkpointData;
        IEOFeedVerifier.LeafInput[] memory inputs;
        vm.expectRevert(MissingLeafInputs.selector);
        registry.updatePriceFeeds(inputs, checkpointData);

        inputs = new IEOFeedVerifier.LeafInput[](2);
        vm.expectRevert(MissingCheckpoint.selector);
        registry.updatePriceFeeds(inputs, checkpointData);
    }

    function test_RevertWhen_SymbolNotSupported_GetLatestPriceFeed() public {
        vm.expectRevert(SymbolNotSupported.selector);
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

    function _setSupportedSymbol(address _executer, uint16 _symbol) private {
        uint16[] memory symbols = new uint16[](1);
        bool[] memory isSupported = new bool[](1);
        symbols[0] = _symbol;
        isSupported[0] = true;
        vm.prank(_executer);
        registry.setSupportedSymbols(symbols, isSupported);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { Utils } from "../utils/Utils.sol";
import { IEOFeedRegistry } from "../../src/interfaces/IEOFeedRegistry.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { EOFeedRegistry } from "../../src/EOFeedRegistry.sol";
import { EOFeedVerifier } from "../../src/EOFeedVerifier.sol";
import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";
import { MockCheckpointManager } from "../mock/MockCheckpointManager.sol";

error OwnableUnauthorizedAccount(address);

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
        verifier = EOFeedVerifier(proxify("EOFeedVerifier.sol", ""));
        registry = EOFeedRegistry(proxify("EOFeedRegistry.sol", ""));
        vm.startPrank(owner);
        verifier.initialize(checkpointManager);
        registry.initialize(verifier);
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
        vm.expectRevert("Caller is not whitelisted");
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
        vm.expectRevert("Symbol is not supported");
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { Utils } from "../utils/Utils.sol";
import { IEOFeedRegistry } from "../../src/interfaces/IEOFeedRegistry.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { EOFeedRegistry } from "../../src/EOFeedRegistry.sol";
import { EOFeedVerifier } from "../../src/EOFeedVerifier.sol";
import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";
import { DeployFeedRegistry } from "../../script/deployment/base/DeployFeedRegistry.s.sol";

import { TargetCheckpointManager } from "../../src/TargetCheckpointManager.sol";
import { BLS } from "../../src/common/BLS.sol";
import { BN256G2 } from "../../src/common/BN256G2.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { DeployFeedVerifier } from "../../script/deployment/base/DeployFeedVerifier.s.sol";
import { DeployCheckpointManager } from "../../script/deployment/base/DeployCheckpointManager.s.sol";

// solhint-disable max-states-count
contract IntegrationTests is Test, Utils {
    struct CheckpointData {
        uint256[2] signature;
        bytes bitmap;
        uint256 epochNumber;
        uint256 blockNumber;
        bytes32 blockHash;
        uint256 blockRound;
        bytes32 currentValidatorSetHash;
        bytes32 eventRoot;
    }

    EOFeedRegistry public registry;
    EOFeedVerifier public feedVerifier;
    TargetCheckpointManager public checkpointManager;

    DeployFeedVerifier public deployerFeedVerifier;
    DeployCheckpointManager public deployerCheckpointManager;
    DeployFeedRegistry public deployerFeedRegistry;

    address public publisher = makeAddr("publisher");
    address public owner;
    address public notOwner = makeAddr("notOwner");
    uint16 public symbol = 1;
    uint256 public rate = 100;
    uint256 public timestamp = 9_999_999_999;
    bytes32 public blockHash = keccak256("BLOCK_HASH");
    bytes32 public eventRoot = keccak256("EVENT_ROOT");
    bytes32 public validatorSetHash = keccak256("VALIDATOR_SET_HASH");
    uint256 public blockRound = 0;
    uint256 public epochNumber = 1;
    uint256 public blockNumber = 1;

    BLS public bls;
    BN256G2 public bn256G2;

    uint256 public childChainId = 1;
    uint256 public validatorSetSize;
    ICheckpointManager.Validator[] public validatorSet;
    IEOFeedVerifier.LeafInput[] public leafInputs;

    address public admin;
    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
    bytes32[] public hashes;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    bytes[] public unhashedLeaves;
    bytes32[][] public proves;
    bytes32[][] public leavesArray;
    bytes[] public symbolData;

    IEOFeedVerifier.LeafInput[] public input;
    bytes[] public checkpointData;

    function setUp() public {
        // proxy admin
        admin = makeAddr("admin");
        // deployer, owner of contracts
        owner = address(this);

        bls = new BLS();
        bn256G2 = new BN256G2();

        // can be seeded up to 4 leaves
        _seedSymbolData();
        _generatePayload(symbolData);

        deployerCheckpointManager = new DeployCheckpointManager();
        address proxyAddressCheckpointManager = deployerCheckpointManager.run(admin, bls, bn256G2, childChainId, owner);
        checkpointManager = TargetCheckpointManager(proxyAddressCheckpointManager);
        checkpointManager.setNewValidatorSet(validatorSet);

        deployerFeedVerifier = new DeployFeedVerifier();
        address proxyAddressFeedVerifier = deployerFeedVerifier.run(admin, checkpointManager, owner);
        feedVerifier = EOFeedVerifier(proxyAddressFeedVerifier);

        deployerFeedRegistry = new DeployFeedRegistry();
        address proxyAddressFeedRegistry = deployerFeedRegistry.run(admin, feedVerifier, owner);
        registry = EOFeedRegistry(proxyAddressFeedRegistry);
        _whitelistPublisher(owner, publisher);
    }

    /**
     * @notice update first symbol
     */
    function test_updatePriceFeed() public {
        _setSupportedSymbol(owner, symbol);
        vm.prank(publisher);
        registry.updatePriceFeed(input[0], checkpointData[0]);
        IEOFeedRegistry.PriceFeed memory feed = registry.getLatestPriceFeed(symbol);
        assertEq(feed.value, rate);
    }

    /**
     * @notice update second symbol
     */
    function test_updatePriceFeed2() public {
        _setSupportedSymbol(owner, symbol + 1);
        vm.prank(publisher);
        registry.updatePriceFeed(input[1], checkpointData[1]);
        IEOFeedRegistry.PriceFeed memory feed = registry.getLatestPriceFeed(symbol + 1);
        assertEq(feed.value, rate + 1);
    }

    /**
     * @notice update first symbol and then second symbol
     */
    function test_updatePriceFeed_SeparateCalls() public {
        test_updatePriceFeed();
        test_updatePriceFeed2();
    }

    /**
     * @notice update first and second symbol symultaneously
     */
    function test_updatePriceFeeds() public {
        _setSupportedSymbol(owner, symbol);
        _setSupportedSymbol(owner, symbol + 1);
        vm.prank(publisher);
        registry.updatePriceFeeds(input, checkpointData[1]);
        IEOFeedRegistry.PriceFeed memory feed = registry.getLatestPriceFeed(symbol);
        assertEq(feed.value, rate);
        feed = registry.getLatestPriceFeed(symbol + 1);
        assertEq(feed.value, rate + 1);
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

    function _generatePayload(bytes[] memory _symbolData) private {
        require(_symbolData.length > 0, "SYMBOLDATA_EMPTY");
        require(_symbolData.length <= 4, "SYMBOLDATA_TOO_LARGE");
        uint256 len = 4 + _symbolData.length;
        string[] memory cmd = new string[](len);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/utils/ts/generateMsgProofRates.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN));
        for (uint256 i = 0; i < _symbolData.length; i++) {
            cmd[4 + i] = vm.toString(_symbolData[i]);
        }

        bytes memory out = vm.ffi(cmd);

        ICheckpointManager.Validator[] memory validatorSetTmp;

        (validatorSetSize, validatorSetTmp, aggMessagePoints, hashes, bitmaps, unhashedLeaves, proves, leavesArray) =
        abi.decode(
            out,
            (
                uint256,
                ICheckpointManager.Validator[],
                uint256[2][],
                bytes32[],
                bytes[],
                bytes[],
                bytes32[][],
                bytes32[][]
            )
        );

        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }

        for (uint256 i = 0; i < _symbolData.length; i++) {
            input.push(
                IEOFeedVerifier.LeafInput({
                    unhashedLeaf: unhashedLeaves[i],
                    leafIndex: i,
                    blockNumber: 1,
                    proof: proves[i]
                })
            );

            // solhint-disable-next-line func-named-parameters
            checkpointData.push(
                abi.encode(
                    aggMessagePoints[0], // signature
                    bitmaps[0], // bitmap
                    1, // epochNumber
                    1,
                    hashes[1], // blockHash
                    0, // blockRound
                    hashes[2], // currentValidatorSetHash
                    hashes[0]
                )
            );
        }
    }

    function _seedSymbolData() private {
        symbolData.push(abi.encode(symbol, rate, timestamp));
        symbolData.push(abi.encode(symbol + 1, rate + 1, timestamp));
    }
}

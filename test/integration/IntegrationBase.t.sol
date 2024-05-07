// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { Utils } from "../utils/Utils.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { EOFeedRegistry } from "../../src/EOFeedRegistry.sol";
import { EOFeedVerifier } from "../../src/EOFeedVerifier.sol";
import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";
import { DeployFeedRegistry } from "../../script/deployment/base/DeployFeedRegistry.s.sol";

import { TargetCheckpointManager } from "../../src/TargetCheckpointManager.sol";
import { BLS } from "../../src/common/BLS.sol";
import { BN256G2 } from "../../src/common/BN256G2.sol";
import { DeployFeedVerifier } from "../../script/deployment/base/DeployFeedVerifier.s.sol";
import { DeployCheckpointManager } from "../../script/deployment/base/DeployCheckpointManager.s.sol";

// solhint-disable max-states-count
abstract contract IntegrationBaseTests is Test, Utils {
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
    uint16[] public symbols;
    uint256[] public rates;
    uint256[] public timestamps;
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
    uint256 public constant VALIDATOR_SET_SIZE = 10;
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
        _setAllSupportedSymbols(owner);
    }

    function _whitelistPublisher(address _executer, address _publisher) internal {
        address[] memory publishers = new address[](1);
        bool[] memory isWhitelisted = new bool[](1);
        publishers[0] = _publisher;
        isWhitelisted[0] = true;
        vm.prank(_executer);
        registry.whitelistPublishers(publishers, isWhitelisted);
    }

    function _setAllSupportedSymbols(address _executer) internal {
        uint256 len = symbols.length;
        bool[] memory isSupported = new bool[](len);
        uint16[] memory symbolsSupported = new uint16[](len);
        for (uint256 i = 0; i < len; i++) {
            isSupported[i] = true;
            symbolsSupported[i] = symbols[i];
        }
        vm.prank(_executer);
        registry.setSupportedSymbols(symbolsSupported, isSupported);
    }

    function _generatePayload(bytes[] memory _symbolData) internal virtual;

    function _seedSymbolData() internal virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test, console } from "forge-std/Test.sol";
import { stdJson } from "forge-std/Script.sol";
import { Utils } from "../utils/Utils.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { EOFeedRegistry } from "../../src/EOFeedRegistry.sol";
import { EOFeedVerifier } from "../../src/EOFeedVerifier.sol";
import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";

import { TargetCheckpointManager } from "../../src/TargetCheckpointManager.sol";
import { DeployNewTargetContractSet } from "../../script/deployment/DeployNewTargetContractSet.s.sol";
import { EOJsonUtils } from "../../script/utils/EOJsonUtils.sol";
import { DeployFeedRegistryAdapter } from "../../script/deployment/DeployFeedRegistryAdapter.s.sol";
import { SetupCoreContracts } from "../../script/deployment/setup/SetupCoreContracts.s.sol";
// solhint-disable max-states-count
import { EOJsonUtils } from "../..//script/utils/EOJsonUtils.sol";

abstract contract IntegrationBaseTests is Test, Utils {
    using stdJson for string;

    EOFeedRegistry public feedRegistry;
    EOFeedVerifier public feedVerifier;
    TargetCheckpointManager public checkpointManager;

    DeployNewTargetContractSet public mainDeployer;
    DeployFeedRegistryAdapter public adapterDeployer;
    SetupCoreContracts public coreContractsSetup;

    address public publisher;
    address public owner;
    address public feedImplementation;
    address public adapterProxy;

    uint16[] public symbols;
    uint256[] public rates;
    uint256[] public timestamps;
    uint256 public blockRound = 0;
    uint256 public epochNumber = 1;
    // TODO: pass to ts as argument
    uint256 public blockNumber = 1;
    uint256 public childChainId;
    uint256 public validatorSetSize;
    bytes[] public symbolData;
    ICheckpointManager.Validator[] public validatorSet;

    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
    uint256 public constant VALIDATOR_SET_SIZE = 10;

    // generated by _generatePayload function
    IEOFeedVerifier.LeafInput[] public input;
    ICheckpointManager.CheckpointMetadata[] public checkpointMetas;
    ICheckpointManager.Checkpoint[] public checkpoints;
    uint256[2][] public signatures;
    bytes[] public bitmaps;

    function setUp() public {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        publisher = configStructured.publishers[0];
        owner = configStructured.targetContractsOwner;
        childChainId = configStructured.childChainId;

        mainDeployer = new DeployNewTargetContractSet();
        adapterDeployer = new DeployFeedRegistryAdapter();
        coreContractsSetup = new SetupCoreContracts();

        address checkpointManagerAddr;
        address feedVerifierAddr;
        address feedRegistryAddr;

        (,, checkpointManagerAddr, feedVerifierAddr, feedRegistryAddr) = mainDeployer.run();
        // vm.prank(owner);
        uint256 prKey = vm.envOr({ name: "PRIVATE_KEY", defaultValue: uint256(0) });
        address _broadcaster = vm.addr(prKey);
        console.logAddress(_broadcaster);
        console.logAddress(EOFeedRegistry(feedRegistryAddr).owner());

        coreContractsSetup.run();
        (feedImplementation, adapterProxy) = adapterDeployer.run();

        checkpointManager = TargetCheckpointManager(checkpointManagerAddr);
        feedVerifier = EOFeedVerifier(feedVerifierAddr);
        feedRegistry = EOFeedRegistry(feedRegistryAddr);

        _seedSymbolData(configStructured);
        _generatePayload(symbolData);

        this._setValidatorSet(validatorSet);
    }

    function _setValidatorSet(ICheckpointManager.Validator[] calldata _validatorSet) public {
        vm.prank(owner);
        checkpointManager.setNewValidatorSet(_validatorSet);
    }

    function _setSupportedSymbols(uint16[] memory symbolsSupported) public {
        bool[] memory isSupported = new bool[](symbolsSupported.length);
        for (uint256 i = 0; i < symbolsSupported.length; i++) {
            isSupported[i] = true;
        }
        vm.prank(owner);
        feedRegistry.setSupportedSymbols(symbolsSupported, isSupported);
    }

    function _whitelistPublisher(address _publisher) public {
        address[] memory publishers = new address[](1);
        bool[] memory isWhitelisted = new bool[](1);
        publishers[0] = _publisher;
        isWhitelisted[0] = true;
        vm.prank(owner);
        feedRegistry.whitelistPublishers(publishers, isWhitelisted);
    }

    function _generatePayload(bytes[] memory _symbolData) internal virtual;

    function _seedSymbolData(EOJsonUtils.Config memory configStructured) internal virtual;
}

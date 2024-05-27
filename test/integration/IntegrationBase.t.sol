// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { stdJson } from "forge-std/Script.sol";
import { Utils } from "../utils/Utils.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { EOFeedManager } from "../../src/EOFeedManager.sol";
import { EOFeedRegistryAdapter } from "../../src/adapters/EOFeedRegistryAdapter.sol";
import { EOFeedVerifier } from "../../src/EOFeedVerifier.sol";
import { DeployNewTargetContractSet } from "../../script/deployment/DeployNewTargetContractSet.s.sol";
import { EOJsonUtils } from "../../script/utils/EOJsonUtils.sol";
import { DeployFeedRegistryAdapter } from "../../script/deployment/DeployFeedRegistryAdapter.s.sol";
import { DeployFeeds } from "../../script/deployment/DeployFeeds.s.sol";
import { SetupCoreContracts } from "../../script/deployment/setup/SetupCoreContracts.s.sol";
// solhint-disable max-states-count
import { EOJsonUtils } from "../..//script/utils/EOJsonUtils.sol";

abstract contract IntegrationBaseTests is Test, Utils {
    using stdJson for string;

    EOFeedManager public _feedManager;
    EOFeedRegistryAdapter public _feedRegistryAdapter;
    EOFeedVerifier public _feedVerifier;

    address public _publisher;
    address public _owner;

    uint16[] public _feedIds;
    uint256[] public _rates;
    uint256[] public _timestamps;
    // TODO: pass to ts as argument
    uint256 public validatorSetSize;
    bytes[] public feedsData;
    IEOFeedVerifier.Validator[] public validatorSet;

    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
    uint256 public constant VALIDATOR_SET_SIZE = 10;

    // generated by _generatePayload function
    IEOFeedVerifier.LeafInput[] public input;
    IEOFeedVerifier.Checkpoint[] public checkpoints;
    uint256[2][] public signatures;
    bytes[] public bitmaps;

    function setUp() public {
        EOJsonUtils.Config memory configStructured = EOJsonUtils.getParsedConfig();

        _publisher = configStructured.publishers[0];
        _owner = configStructured.targetContractsOwner;

        DeployNewTargetContractSet mainDeployer = new DeployNewTargetContractSet();
        DeployFeedRegistryAdapter adapterDeployer = new DeployFeedRegistryAdapter();
        SetupCoreContracts coreContractsSetup = new SetupCoreContracts();
        DeployFeeds feedsDeployer = new DeployFeeds();

        address feedVerifierAddr;
        address feedManagerAddr;

        (,, feedVerifierAddr, feedManagerAddr) = mainDeployer.run(_owner);
        coreContractsSetup.run(_owner);
        address feedRegistryAdapterAddress;
        (, feedRegistryAdapterAddress) = adapterDeployer.run();
        feedsDeployer.run(_owner);

        _feedVerifier = EOFeedVerifier(feedVerifierAddr);
        _feedManager = EOFeedManager(feedManagerAddr);
        _feedRegistryAdapter = EOFeedRegistryAdapter(feedRegistryAdapterAddress);

        _seedfeedsData(configStructured);
        _generatePayload(feedsData);

        this._setValidatorSet(validatorSet);
    }

    function _setValidatorSet(IEOFeedVerifier.Validator[] calldata _validatorSet) public {
        vm.prank(_owner);
        _feedVerifier.setNewValidatorSet(_validatorSet);
    }

    function _setSupportedFeeds(uint16[] memory feedsSupported) public {
        bool[] memory isSupported = new bool[](feedsSupported.length);
        for (uint256 i = 0; i < feedsSupported.length; i++) {
            isSupported[i] = true;
        }
        vm.prank(_owner);
        _feedManager.setSupportedFeeds(feedsSupported, isSupported);
    }

    function _whitelistPublisher(address publisher) public {
        address[] memory publishers = new address[](1);
        bool[] memory isWhitelisted = new bool[](1);
        publishers[0] = publisher;
        isWhitelisted[0] = true;
        vm.prank(_owner);
        _feedManager.whitelistPublishers(publishers, isWhitelisted);
    }

    function _generatePayload(bytes[] memory _feedsData) internal virtual;

    function _seedfeedsData(EOJsonUtils.Config memory configStructured) internal virtual;
}

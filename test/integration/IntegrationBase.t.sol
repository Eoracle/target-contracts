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

        (,, feedVerifierAddr, feedManagerAddr) = mainDeployer.run();
        coreContractsSetup.run(_owner);
        address feedRegistryAdapterAddress;
        (, feedRegistryAdapterAddress) = adapterDeployer.run();
        feedsDeployer.run(_owner);

        _feedVerifier = EOFeedVerifier(feedVerifierAddr);
        _feedManager = EOFeedManager(feedManagerAddr);
        _feedRegistryAdapter = EOFeedRegistryAdapter(feedRegistryAdapterAddress);

        _seedfeedsData(configStructured, uint256(100));
        _generatePayload(feedsData);

        _setValidatorSet(validatorSet);
    }

    function _setValidatorSet(IEOFeedVerifier.Validator[] memory _validatorSet) internal {
        vm.prank(_owner);
        _feedVerifier.setNewValidatorSet(_validatorSet);
    }

    function _setSupportedFeeds(uint16[] memory feedsSupported) internal {
        bool[] memory isSupported = new bool[](feedsSupported.length);
        for (uint256 i = 0; i < feedsSupported.length; i++) {
            isSupported[i] = true;
        }
        vm.prank(_owner);
        _feedManager.setSupportedFeeds(feedsSupported, isSupported);
    }

    function _whitelistPublisher(address publisher) internal {
        address[] memory publishers = new address[](1);
        bool[] memory isWhitelisted = new bool[](1);
        publishers[0] = publisher;
        isWhitelisted[0] = true;
        vm.prank(_owner);
        _feedManager.whitelistPublishers(publishers, isWhitelisted);
    }

    function _generatePayload(bytes[] memory _feedsData) internal virtual {
        require(_feedsData.length > 0, "FEEDSDATA_EMPTY");
        delete validatorSet;
        delete input;
        delete checkpoints;
        delete signatures;
        delete bitmaps;

        uint256 blockNumber = block.number;
        uint256 len = 6 + _feedsData.length;
        string[] memory cmd = new string[](len);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/utils/ts/generateMsgProofRates.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN));
        cmd[4] = vm.toString(abi.encode(VALIDATOR_SET_SIZE));
        cmd[5] = vm.toString(abi.encode(blockNumber));
        for (uint256 i = 0; i < _feedsData.length; i++) {
            cmd[6 + i] = vm.toString(_feedsData[i]);
        }

        bytes memory out = vm.ffi(cmd);
        bytes[] memory unhashedLeaves;
        bytes32[][] memory proves;
        bytes32[] memory hashes;
        bytes[] memory _bitmaps;
        uint256[2][] memory aggMessagePoints;

        IEOFeedVerifier.Validator[] memory validatorSetTmp;

        (validatorSetSize, validatorSetTmp, aggMessagePoints, hashes, _bitmaps, unhashedLeaves, proves,) = abi.decode(
            out,
            (uint256, IEOFeedVerifier.Validator[], uint256[2][], bytes32[], bytes[], bytes[], bytes32[][], bytes32[][])
        );

        for (uint256 i = 0; i < validatorSetSize; i++) {
            validatorSet.push(validatorSetTmp[i]);
        }

        for (uint256 i = 0; i < _feedsData.length; i++) {
            input.push(IEOFeedVerifier.LeafInput({ unhashedLeaf: unhashedLeaves[i], leafIndex: i, proof: proves[i] }));

            // solhint-disable-next-line func-named-parameters
        }
        signatures.push(aggMessagePoints[0]);
        checkpoints.push(
            IEOFeedVerifier.Checkpoint({
                blockNumber: blockNumber,
                epoch: 1,
                eventRoot: hashes[0],
                blockHash: hashes[1],
                blockRound: 0
            })
        );

        bitmaps.push(_bitmaps[0]);
    }

    function _seedfeedsData(EOJsonUtils.Config memory configStructured, uint256 initialRate) internal virtual {
        delete feedsData;
        delete _rates;
        delete _feedIds;
        delete _timestamps;
        for (uint256 i = 0; i < configStructured.supportedFeedIds.length; i++) {
            _feedIds.push(uint16(configStructured.supportedFeedIds[i]));
            _rates.push(initialRate + configStructured.supportedFeedIds[i]);
            _timestamps.push(block.timestamp);
            feedsData.push(abi.encode(_feedIds[i], _rates[i], _timestamps[i]));
        }
    }
}

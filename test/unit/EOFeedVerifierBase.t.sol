// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { TargetCheckpointManager } from "../../src/TargetCheckpointManager.sol";
import { EOFeedVerifier } from "../../src/EOFeedVerifier.sol";
import { BLS } from "../../src/common/BLS.sol";
import { BN256G2 } from "../../src/common/BN256G2.sol";
import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { DeployFeedVerifier } from "../../script/deployment/base/DeployFeedVerifier.s.sol";

// solhint-disable max-states-count
abstract contract UninitializedFeedVerifier is Test {
    struct ProofData {
        uint256[2] signature;
        bytes bitmap;
        bytes unhashedLeaf;
        uint256 leafIndex;
        uint256 epochNumber;
        uint256 blockNumber;
        bytes32 blockHash;
        uint256 blockRound;
        bytes32 currentValidatorSetHash;
        bytes32 eventRoot;
        bytes32[] proof;
    }

    EOFeedVerifier public feedVerifier;
    TargetCheckpointManager public checkpointManager;
    BLS public bls;
    BN256G2 public bn256G2;
    DeployFeedVerifier public deployer;

    uint256 public childChainId = 1;
    uint256 public validatorSetSize;
    ICheckpointManager.Validator[] public validatorSet;
    IEOFeedVerifier.BatchExitInput[] public batchExitInput;

    address public admin;
    address public alice;
    address public bob;
    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
    bytes32[] public hashes;
    bytes32[] public proof;
    bytes[] public bitmaps;
    uint256[2][] public aggMessagePoints;
    bytes[] public unhashedLeaves;
    bytes32[][] public proves;
    bytes32[][] public leavesArray;

    event ExitProcessed(uint256 indexed id, bool indexed success, bytes returnData);

    function setUp() public virtual {
        bls = new BLS();
        bn256G2 = new BN256G2();
        feedVerifier = new EOFeedVerifier();
        deployer = new DeployFeedVerifier();

        admin = makeAddr("admin");
        alice = makeAddr("Alice");
        bob = makeAddr("Bob");

        string[] memory cmd = new string[](4);
        cmd[0] = "npx";
        cmd[1] = "ts-node";
        cmd[2] = "test/utils/ts/generateMsgProof.ts";
        cmd[3] = vm.toString(abi.encode(DOMAIN));
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

        checkpointManager = new TargetCheckpointManager();
        checkpointManager.initialize(bls, bn256G2, childChainId, address(this));
        checkpointManager.setNewValidatorSet(validatorSet);
    }
}

abstract contract InitializedFeedVerifier is UninitializedFeedVerifier {
    function setUp() public virtual override {
        super.setUp();
        address proxyAddress = deployer.run(admin, checkpointManager, address(this));
        feedVerifier = EOFeedVerifier(proxyAddress);
    }
}

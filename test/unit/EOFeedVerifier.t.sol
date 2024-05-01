// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { TargetCheckpointManager } from "../../src/TargetCheckpointManager.sol";
import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";
import { IEOFeedVerifier } from "../../src/interfaces/IEOFeedVerifier.sol";
import { UninitializedFeedVerifier, InitializedFeedVerifier } from "./EOFeedVerifierBase.t.sol";

abstract contract CheckpointSubmitted is InitializedFeedVerifier {
    function setUp() public virtual override {
        super.setUp();

        ICheckpointManager.Checkpoint memory checkpoint =
            ICheckpointManager.Checkpoint({ epoch: 1, blockNumber: 1, eventRoot: hashes[0] });

        ICheckpointManager.Checkpoint memory checkpoint2 =
            ICheckpointManager.Checkpoint({ epoch: 2, blockNumber: 2, eventRoot: hashes[3] });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[0], validatorSet, bitmaps[0]);
        checkpointManager.submit(checkpointMetadata, checkpoint2, aggMessagePoints[1], validatorSet, bitmaps[0]);

        assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
        assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

        uint256 leafIndex = 1;
        assertEq(
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint2.blockNumber, leavesArray[1][leafIndex], leafIndex, proves[2]
            ),
            true
        );
    }
}

abstract contract EOFeedVerifierExited is CheckpointSubmitted {
    function setUp() public virtual override {
        super.setUp();
        uint256 blockNumber = 1;
        uint256 leafIndex = 0;
        feedVerifier.exit(blockNumber, leafIndex, unhashedLeaves[0], proves[0]);
    }
}

contract EOFeedVerifierInitialize is UninitializedFeedVerifier {
    function test_RevertWhen_Initialize_InvalidAddress() public {
        TargetCheckpointManager checkpointManagerNull;
        vm.expectRevert("ExitHelper: INVALID_ADDRESS");
        feedVerifier.initialize(checkpointManagerNull);
    }

    function testInitialize() public {
        feedVerifier.initialize(checkpointManager);
        assertEq(
            keccak256(abi.encode(feedVerifier.getCheckpointManager())),
            keccak256(abi.encode(address(checkpointManager)))
        );
    }
}

contract EOFeedVerifierExitFailedBeforeInitialized is UninitializedFeedVerifier {
    function test_RevertWhen_Exit_Uninitialized() public {
        uint256 blockNumber = 0;
        uint256 leafIndex = 0;
        bytes memory unhashedLeaf = abi.encodePacked(block.timestamp);
        proof.push(keccak256(abi.encodePacked(block.timestamp)));

        vm.expectRevert("EOFeedVerifier: NOT_INITIALIZED");
        feedVerifier.exit(blockNumber, leafIndex, unhashedLeaf, proof);
    }

    function test_RevertWhen_BatchExit_Uninitialized() public {
        uint256 blockNumber = 0;
        uint256 leafIndex = 0;
        bytes memory unhashedLeaf = abi.encodePacked(block.timestamp);
        proof.push(keccak256(abi.encodePacked(block.timestamp)));

        vm.expectRevert("EOFeedVerifier: NOT_INITIALIZED");
        leafInputs.push(IEOFeedVerifier.LeafInput(blockNumber, leafIndex, unhashedLeaf, proof));
        feedVerifier.batchExit(leafInputs);
    }
}

contract EOFeedVerifierExit is InitializedFeedVerifier {
    function test_Exit() public {
        ICheckpointManager.Checkpoint memory checkpoint =
            ICheckpointManager.Checkpoint({ epoch: 1, blockNumber: 1, eventRoot: hashes[0] });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[0], validatorSet, bitmaps[0]);

        assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
        assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

        uint256 leafIndex = 0;
        assertEq(
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint.blockNumber, leavesArray[0][leafIndex], leafIndex, proves[0]
            ),
            true
        );

        uint256 id = 0;
        assertEq(feedVerifier.isProcessedExit(id), false);

        feedVerifier.exit(checkpoint.blockNumber, leafIndex, unhashedLeaves[0], proves[0]);
        assertEq(feedVerifier.isProcessedExit(id), true);
    }

    function test_SubmitAndExit() public {
        IEOFeedVerifier.LeafInput memory input = IEOFeedVerifier.LeafInput({
            unhashedLeaf: unhashedLeaves[0],
            leafIndex: 0,
            blockNumber: 1,
            proof: proves[0]
        });

        bytes32 eventRoot = hashes[0];
        uint256 blockNumber = 1;
        // solhint-disable-next-line func-named-parameters
        bytes memory checkpointData = abi.encode(
            aggMessagePoints[0], // signature
            bitmaps[0], // bitmap
            1, // epochNumber
            blockNumber,
            hashes[1], // blockHash
            0, // blockRound
            hashes[2], // currentValidatorSetHash
            eventRoot
        );

        (uint256 id,,, bytes memory data) = abi.decode(input.unhashedLeaf, (uint256, address, address, bytes));
        vm.expectEmit(true, true, true, true);
        emit ExitProcessed(id, true, data);
        bytes memory leafData = feedVerifier.submitAndExit(input, checkpointData);
        assertEq(leafData, data);

        assertEq(checkpointManager.getEventRootByBlock(blockNumber), hashes[0]);
        assertEq(checkpointManager.checkpointBlockNumbers(0), blockNumber);

        assertEq(
            checkpointManager.getEventMembershipByBlockNumber(
                blockNumber, leavesArray[0][input.leafIndex], input.leafIndex, input.proof
            ),
            true
        );

        assertEq(feedVerifier.isProcessedExit(id), true);
    }
}

contract EOFeedVerifierExitFailedAfterInitialized is CheckpointSubmitted {
    function test_RevertWhen_Exit_InvalidProof() public {
        uint256 blockNumber = 1;
        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));

        vm.expectRevert("ExitHelper: INVALID_PROOF");
        feedVerifier.exit(blockNumber, leafIndex, unhashedLeaves[0], proof);
    }
}

contract EOFeedVerifierExitFailedAfterSubmitted is EOFeedVerifierExited {
    function test_RevertWhen_Exit_AlreadyProcessed() public {
        uint256 blockNumber = 0;
        uint256 leafIndex = 0;

        vm.expectRevert("ExitHelper: EXIT_ALREADY_PROCESSED");
        feedVerifier.exit(blockNumber, leafIndex, unhashedLeaves[0], proves[0]);
    }
}

contract EOFeedVerifierBatchExit is EOFeedVerifierExited {
    function test_BatchExit() public {
        ICheckpointManager.Checkpoint memory checkpoint1 =
            ICheckpointManager.Checkpoint({ epoch: 2, blockNumber: 2, eventRoot: hashes[3] });

        ICheckpointManager.Checkpoint memory checkpoint2 =
            ICheckpointManager.Checkpoint({ epoch: 3, blockNumber: 3, eventRoot: hashes[3] });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint1, aggMessagePoints[1], validatorSet, bitmaps[1]);

        checkpointManager.submit(checkpointMetadata, checkpoint2, aggMessagePoints[2], validatorSet, bitmaps[1]);

        uint256 leafIndex1 = 0;
        uint256 leafIndex2 = 1;
        assertEq(
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint1.blockNumber, leavesArray[1][leafIndex1], leafIndex1, proves[1]
            ),
            true
        );

        assertEq(
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint2.blockNumber, leavesArray[1][leafIndex2], leafIndex2, proves[2]
            ),
            true
        );

        leafInputs.push(IEOFeedVerifier.LeafInput(checkpoint1.blockNumber, leafIndex1, unhashedLeaves[1], proves[1]));

        uint256 id = 1;
        assertEq(feedVerifier.isProcessedExit(id), false);
        assertEq(feedVerifier.isProcessedExit(id + 1), false);

        feedVerifier.batchExit(leafInputs);

        assertEq(feedVerifier.isProcessedExit(id), true);
        assertEq(feedVerifier.isProcessedExit(id + 1), false);

        leafInputs.push(IEOFeedVerifier.LeafInput(checkpoint2.blockNumber, leafIndex2, unhashedLeaves[2], proves[2]));

        feedVerifier.batchExit(leafInputs);

        assertEq(feedVerifier.isProcessedExit(id), true);
        assertEq(feedVerifier.isProcessedExit(id + 1), true);
    }
}

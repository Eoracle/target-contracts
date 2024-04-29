// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";
import { UninitializedCheckpointManager, InitializedCheckpointManager } from "./CheckpointManagerBase.sol";

abstract contract FirstSubmittedCheckpoint is InitializedCheckpointManager {
    function setUp() public virtual override {
        super.setUp();

        ICheckpointManager.Checkpoint memory checkpoint =
            ICheckpointManager.Checkpoint({ epoch: 1, blockNumber: 1, eventRoot: hashes[0] });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[3], validatorSet, bitmaps[3]);
    }
}

contract CheckpointManagerInitializeTest is UninitializedCheckpointManager {
    function test_Initialize() public {
        checkpointManager.initialize(bls, bn256G2, childChainId);
        checkpointManager.setNewValidatorSet(validatorSet);

        assertEq(keccak256(abi.encode(checkpointManager.bls())), keccak256(abi.encode(address(bls))));
        assertEq(keccak256(abi.encode(checkpointManager.bn256G2())), keccak256(abi.encode(address(bn256G2))));
        assertEq(checkpointManager.currentValidatorSetLength(), validatorSetSize);
        for (uint256 i = 0; i < validatorSetSize; i++) {
            (address _address, uint256 votingPower) = checkpointManager.currentValidatorSet(i);
            assertEq(_address, validatorSet[i]._address);
            assertEq(votingPower, validatorSet[i].votingPower);
        }
    }
}

contract CheckpointManagerSubmitTest is InitializedCheckpointManager {
    function test_Submit_RevertWhen_InvalidValidatorSetHash() public {
        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 1,
            blockNumber: 0, //For Invalid Signature
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[1] //Invalid Hash
         });

        vm.expectRevert("INVALID_VALIDATOR_SET_HASH");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[0], validatorSet, bitmaps[0]);
    }

    function test_Submit_RevertWhen_InvalidSignature() public {
        ICheckpointManager.Checkpoint memory checkpoint = ICheckpointManager.Checkpoint({
            epoch: 1,
            blockNumber: 0, //For Invalid Signature
            eventRoot: hashes[0]
        });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        vm.expectRevert("SIGNATURE_VERIFICATION_FAILED");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[0], validatorSet, bitmaps[0]);
    }

    function test_Submit_RevertWhen_EmptyBitmap() public {
        ICheckpointManager.Checkpoint memory checkpoint =
            ICheckpointManager.Checkpoint({ epoch: 1, blockNumber: 1, eventRoot: hashes[0] });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });
        vm.expectRevert("BITMAP_IS_EMPTY");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[1], validatorSet, bitmaps[1]);
    }

    function test_Submit_RevertWhen_NotEnoughPower() public {
        ICheckpointManager.Checkpoint memory checkpoint =
            ICheckpointManager.Checkpoint({ epoch: 1, blockNumber: 1, eventRoot: hashes[0] });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        vm.expectRevert("INSUFFICIENT_VOTING_POWER");
        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[2], validatorSet, bitmaps[2]);
    }

    function test_Submit_First() public {
        ICheckpointManager.Checkpoint memory checkpoint =
            ICheckpointManager.Checkpoint({ epoch: 1, blockNumber: 1, eventRoot: hashes[0] });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[3], validatorSet, bitmaps[3]);

        assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
        assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));
        checkpointManager.getEventMembershipByBlockNumber(
            checkpoint.blockNumber, checkpoint.eventRoot, leafIndex, proof
        );
        checkpointManager.getEventMembershipByEpoch(checkpoint.epoch, checkpoint.eventRoot, leafIndex, proof);
    }
}

contract CheckpointManagerSubmitSecondTest is FirstSubmittedCheckpoint {
    // function test_RevertWhen_Submit_InvalidEpoch() public {
    //     ICheckpointManager.Checkpoint memory checkpoint =
    //         ICheckpointManager.Checkpoint({ epoch: 0, blockNumber: 0, eventRoot: hashes[0] });

    //     ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
    //         blockHash: hashes[1],
    //         blockRound: 0,
    //         currentValidatorSetHash: hashes[2]
    //     });

    //     vm.expectRevert("INVALID_EPOCH");
    //     checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[4], validatorSet, bitmaps[4]);
    // }

    // function test_RevertWhen_Submit_EmptyCheckpoint() public {
    //     ICheckpointManager.Checkpoint memory checkpoint =
    //         ICheckpointManager.Checkpoint({ epoch: 1, blockNumber: 0, eventRoot: hashes[0] });

    //     ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
    //         blockHash: hashes[1],
    //         blockRound: 0,
    //         currentValidatorSetHash: hashes[2]
    //     });

    //     vm.expectRevert("EMPTY_CHECKPOINT");
    //     checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[5], validatorSet, bitmaps[5]);
    // }

    function test_Submit_SameEpoch() public {
        ICheckpointManager.Checkpoint memory checkpoint =
            ICheckpointManager.Checkpoint({ epoch: 1, blockNumber: 2, eventRoot: hashes[0] });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });

        checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[6], validatorSet, bitmaps[6]);

        assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
        assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));
        checkpointManager.getEventMembershipByBlockNumber(
            checkpoint.blockNumber, checkpoint.eventRoot, leafIndex, proof
        );
        checkpointManager.getEventMembershipByEpoch(checkpoint.epoch, checkpoint.eventRoot, leafIndex, proof);
    }

    function test_Submit_ShortBitmap() public {
        ICheckpointManager.Checkpoint memory checkpoint =
            ICheckpointManager.Checkpoint({ epoch: 1, blockNumber: 2, eventRoot: hashes[0] });

        ICheckpointManager.CheckpointMetadata memory checkpointMetadata = ICheckpointManager.CheckpointMetadata({
            blockHash: hashes[1],
            blockRound: 0,
            currentValidatorSetHash: hashes[2]
        });
        // 2/3 of total voting power - a minimum to submit a checkpoint
        if (aggVotingPowers[7] > (checkpointManager.totalVotingPower() * 2) / 3) {
            checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[7], validatorSet, bitmaps[7]);

            assertEq(checkpointManager.getEventRootByBlock(checkpoint.blockNumber), checkpoint.eventRoot);
            assertEq(checkpointManager.checkpointBlockNumbers(0), checkpoint.blockNumber);

            uint256 leafIndex = 0;
            proof.push(keccak256(abi.encodePacked(block.timestamp)));
            checkpointManager.getEventMembershipByBlockNumber(
                checkpoint.blockNumber, checkpoint.eventRoot, leafIndex, proof
            );
            checkpointManager.getEventMembershipByEpoch(checkpoint.epoch, checkpoint.eventRoot, leafIndex, proof);
        } else {
            vm.expectRevert("INSUFFICIENT_VOTING_POWER");
            checkpointManager.submit(checkpointMetadata, checkpoint, aggMessagePoints[7], validatorSet, bitmaps[7]);
        }
    }

    function test_RevertWhen_InvalidEventRootByBlockNumber() public {
        uint256 blockNumber = 3;
        bytes32 leaf = keccak256(abi.encodePacked(block.timestamp));
        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));
        vm.expectRevert("NO_EVENT_ROOT_FOR_BLOCK_NUMBER");
        checkpointManager.getEventMembershipByBlockNumber(blockNumber, leaf, leafIndex, proof);
    }

    function test_RevertWhen_InvalidEventRootByEpoch() public {
        uint256 epoch = 2;
        bytes32 leaf = keccak256(abi.encodePacked(block.timestamp));
        uint256 leafIndex = 0;
        proof.push(keccak256(abi.encodePacked(block.timestamp)));
        vm.expectRevert("NO_EVENT_ROOT_FOR_EPOCH");
        checkpointManager.getEventMembershipByEpoch(epoch, leaf, leafIndex, proof);
    }

    function test_GetCheckpointBlock_BlockNumberIsCheckpointBlock() public view {
        uint256 expectedCheckpointBlock = 1;
        uint256 blockNumber = 1;

        (bool isFound, uint256 foundCheckpointBlock) = checkpointManager.getCheckpointBlock(blockNumber);
        assertEq(foundCheckpointBlock, expectedCheckpointBlock);
        assertEq(isFound, true);
    }

    function test_GetCheckpointBlock_NonExistingCheckpointBlock() public view {
        uint256 expectedCheckpointBlock = 0;
        uint256 blockNumber = 5;

        (bool isFound, uint256 foundCheckpointBlock) = checkpointManager.getCheckpointBlock(blockNumber);
        assertEq(foundCheckpointBlock, expectedCheckpointBlock);
        assertEq(isFound, false);
    }
}

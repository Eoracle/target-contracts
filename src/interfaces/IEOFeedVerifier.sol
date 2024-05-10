// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ICheckpointManager } from "./ICheckpointManager.sol";

/**
 * @title EOFeedManager
 * @author Lightblocks
 * @notice Helper contract to process state syncs from EOracle chain
 */
interface IEOFeedVerifier {
    struct LeafInput {
        uint256 blockNumber;
        uint256 leafIndex;
        bytes unhashedLeaf;
        bytes32[] proof;
    }

    event ExitProcessed(uint256 indexed id, bool indexed success, bytes returnData);
    event LeafVerified(uint256 indexed id, bytes returnData);
    /**
     * @notice Perform an exit (verify) for one event
     * @param input Exit leaf input
     */

    function exit(LeafInput calldata input) external;

    /**
     * @notice Submit a proof and exit (verify) leaf
     * @param input Exit leaf input
     * @param checkpointMetadata Metadata for the checkpoint
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function submitAndVerify(
        LeafInput memory input,
        ICheckpointManager.CheckpointMetadata calldata checkpointMetadata,
        ICheckpointManager.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        returns (bytes memory leafData);

    /**
     * @notice Submit checkpoint and verify multiple leaves
     * @param inputs Exit leaves inputs
     * @param checkpointMetadata Metadata for the checkpoint
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function submitAndBatchVerify(
        LeafInput[] memory inputs,
        ICheckpointManager.CheckpointMetadata calldata checkpointMetadata,
        ICheckpointManager.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        returns (bytes[] memory);

    /**
     * @notice Perform a batch exit for multiple events
     * @param inputs Batch exit inputs for multiple event leaves
     */
    function batchExit(LeafInput[] calldata inputs) external;

    function getCheckpointManager() external view returns (ICheckpointManager);
}

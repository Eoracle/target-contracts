// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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

    /**
     * @notice Perform an exit (verify) for one event
     * @param input Exit leaf input
     */
    function exit(LeafInput calldata input) external;

    /**
     * @notice Submit a proof and exit (verify) leaf
     * @param input Exit leaf input
     * @param checkpointData checkpoint data for verifying the exit
     */
    function submitAndExit(
        LeafInput memory input,
        bytes calldata checkpointData
    )
        external
        returns (bytes memory leafData);

    /**
     * @notice Submit checkpoint and verify multiple leaves
     * @param inputs Exit leaves inputs
     * @param checkpointData checkpoint data for verifying the exit
     */
    function submitAndBatchExit(
        LeafInput[] memory inputs,
        bytes calldata checkpointData
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

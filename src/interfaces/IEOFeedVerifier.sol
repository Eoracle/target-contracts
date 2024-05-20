// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title EOFeedManager
 * @author Lightblocks
 * @notice Helper contract to process state syncs from EOracle chain
 */
interface IEOFeedVerifier {
    struct LeafInput {
        uint256 leafIndex;
        bytes unhashedLeaf;
        bytes32[] proof;
    }

    struct Checkpoint {
        uint256 epoch;
        uint256 blockNumber;
        bytes32 eventRoot;
        bytes32 blockHash;
        uint256 blockRound;
    }

    struct Validator {
        address _address;
        uint256[4] blsKey;
        uint256 votingPower;
    }

    event LeafVerified(uint256 indexed id, bytes returnData);
    event ValidatorSetUpdated(
        uint256 currentValidatorSetLength, bytes32 currentValidatorSetHash, uint256 totalVotingPower
    );

    /**
     * @notice Function to set a new validator set for the CheckpointManager
     * @param newValidatorSet The new validator set to store
     */
    function setNewValidatorSet(Validator[] calldata newValidatorSet) external;

    /**
     * @notice Verify a batch of exits leaves
     * @param inputs Batch exit inputs for multiple event leaves
     * @param eventRoot the root this event should belong to
     * @return Array of the leaf data fields of all submitted leaves
     */
    function verifyLeaves(LeafInput[] calldata inputs, bytes32 eventRoot) external returns (bytes[] memory);

    /**
     * @notice Verify for one event
     * @param input Exit leaf input
     * @param eventRoot event root the leaf should belong to
     * @return The leaf data field
     */
    function verifyLeaf(LeafInput calldata input, bytes32 eventRoot) external returns (bytes memory);

    /**
     * @notice Verify the signature of the checkpoint
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function verifySignature(
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        view;
}

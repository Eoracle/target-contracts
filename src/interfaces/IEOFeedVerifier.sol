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

    event ExitProcessed(uint256 indexed id, bool indexed success, bytes returnData);
    event LeafVerified(uint256 indexed id, bytes returnData);

    /**
     * @notice Verifies leaf
     * @param input Exit leaf input
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function verify(
        LeafInput memory input,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        returns (bytes memory leafData);

    /**
     * @notice Verifies multiple leaves
     * @param inputs Exit leaves inputs
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function batchVerify(
        LeafInput[] memory inputs,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        returns (bytes[] memory);

    /**
     * @notice Function to set a new validator set for the CheckpointManager
     * @param newValidatorSet The new validator set to store
     */
    function setNewValidatorSet(Validator[] calldata newValidatorSet) external;

    function checkEventMembership(
        bytes32, /* eventRoot */
        bytes32, /* leaf */
        uint256, /* leafIndex */
        bytes32[] calldata /* proof */
    )
        external
        pure
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IEOFeedVerifier {
    /**
     * @dev Leaf input structure
     * @param leafIndex Index of the leaf
     * @param unhashedLeaf Unhashed leaf data
     *         abi encoded (uint256 id, address sender, address receiver, bytes memory data)
     *              where bytes memory data =  abi encoded (uint16 feedId, uint256 rate, uint256 timestamp)
     * @param proof Merkle proof of the leaf
     */
    struct LeafInput {
        uint256 leafIndex;
        bytes unhashedLeaf;
        bytes32[] proof;
    }

    /**
     * @dev Checkpoint structure
     * @param epoch Epoch number
     * @param blockNumber Block number
     * @param eventRoot Event root of the merkle tree
     * @param blockHash Block hash
     * @param blockRound Block round
     */
    struct Checkpoint {
        uint256 epoch;
        uint256 blockNumber;
        bytes32 eventRoot;
        bytes32 blockHash;
        uint256 blockRound;
    }

    /**
     * @dev Validator structure
     * @param _address Validator address
     * @param blsKey Validator BLS key
     * @param votingPower Validator voting power
     */
    struct Validator {
        address _address;
        uint256[4] blsKey;
        uint256 votingPower;
    }

    /**
     * @dev Event emitted when the validator set is updated
     * @param currentValidatorSetLength Length of the current validator set
     * @param currentValidatorSetHash Hash of the current validator set
     * @param totalVotingPower Total voting power of the current validator set
     */
    event ValidatorSetUpdated(
        uint256 currentValidatorSetLength, bytes32 currentValidatorSetHash, uint256 totalVotingPower
    );

    /**
     * @dev Event emitted when the feed manager is set
     * @param feedManager Address of the feed manager
     */
    event FeedManagerSet(address feedManager);

    /**
     * @notice Verifies leaf, processes checkpoint,
     *          returns leaf data in case if checkpoint is valid and leaf is part of the merkle tree
     * @param input leaf input data and proof (LeafInput)
     * @param checkpoint Checkpoint data (Checkpoint)
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     * @return leafData Leaf data, abi encoded (uint16 feedId, uint256 rate, uint256 timestamp)
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
     * @notice Verifies multiple leaves, processes checkpoint,
     *          returns leaf data in case if checkpoint is valid and leaves are part of the merkle tree
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
     * @notice Function to set a new validator set
     * @param newValidatorSet The new validator set to store
     */
    function setNewValidatorSet(Validator[] calldata newValidatorSet) external;

    /**
     * @notice Sets the address of the feed manager.
     * @param feedManager_ The address of the new feed manager.
     */
    function setFeedManager(address feedManager_) external;

    /**
     * @notice Sets allowed sender for exit events
     * @param senders Addresses of the allowed senders
     * @param allowed Boolean value to set the sender as allowed or not
     */
    function setAllowedSenders(address[] calldata senders, bool allowed) external;
}

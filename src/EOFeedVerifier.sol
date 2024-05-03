// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ICheckpointManager } from "./interfaces/ICheckpointManager.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";

import { Merkle } from "./common/Merkle.sol";

using Merkle for bytes32;

contract EOFeedVerifier is IEOFeedVerifier, OwnableUpgradeable {
    mapping(uint256 => bool) internal _processedExits;
    ICheckpointManager internal _checkpointManager;

    modifier onlyInitialized() {
        require(address(_checkpointManager) != address(0), "NOT_INITIALIZED");

        _;
    }

    /**
     * @notice Initialize the contract with the checkpoint manager address
     * @dev The checkpoint manager contract must be deployed first
     * @param newCheckpointManager Address of the checkpoint manager contract
     * @param owner Owner of the contract
     */
    function initialize(ICheckpointManager newCheckpointManager, address owner) external initializer {
        require(
            address(newCheckpointManager) != address(0) && address(newCheckpointManager).code.length != 0,
            "INVALID_ADDRESS"
        );
        _checkpointManager = newCheckpointManager;
        __Ownable_init(owner);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     * @dev This function is used to process an exit for one event
     * @param input Exit leaf input
     */
    function exit(LeafInput calldata input) external onlyInitialized {
        _exit(input, false);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function submitAndExit(
        LeafInput calldata input,
        bytes calldata checkpointData
    )
        external
        onlyInitialized
        returns (bytes memory)
    {
        _submitCheckpoint(checkpointData);
        bytes memory data = _exit(input, false);
        return data;
    }

    /**
     * @notice Perform a batch exit for multiple events
     * @param inputs Batch exit inputs for multiple event leaves
     */
    function batchExit(LeafInput[] calldata inputs) external onlyInitialized {
        _batchExit(inputs);
    }

    /**
     * @notice Perform a batch exit for multiple events + submit checkpoint for them
     * @param inputs Batch exit inputs for multiple event leaves
     * @param checkpointData Checkpoint data for verifying the batch exits
     * @return Array of the leaf data fields of all submitted leaves
     */
    function submitAndBatchExit(
        LeafInput[] calldata inputs,
        bytes calldata checkpointData
    )
        external
        onlyInitialized
        returns (bytes[] memory)
    {
        _submitCheckpoint(checkpointData);
        return _batchExit(inputs);
    }

    /**
     * @notice Check if an exit has been processed
     * @param id ID of the exit
     * @return Boolean value indicating if the exit has been processed
     */
    function isProcessedExit(uint256 id) external view returns (bool) {
        return _processedExits[id];
    }

    /**
     * @notice Get the address of the checkpoint manager contract
     * @return Address of the checkpoint manager contract
     */
    function getCheckpointManager() external view returns (ICheckpointManager) {
        return _checkpointManager;
    }

    /**
     * @notice Process a batch of exits
     * @param inputs Batch exit inputs for multiple event leaves
     * @return Array of the leaf data fields of all submitted leaves
     */
    function _batchExit(LeafInput[] calldata inputs) internal returns (bytes[] memory) {
        uint256 length = inputs.length;
        bytes[] memory returnData = new bytes[](length);
        for (uint256 i = 0; i < length;) {
            returnData[i] = _exit(inputs[i], true);
            unchecked {
                ++i;
            }
        }
        return returnData;
    }

    /**
     * @notice Process an exit for one event
     * @param input Exit leaf input
     * @param isBatch Boolean value indicating if the exit is part of a batch
     */
    function _exit(LeafInput calldata input, bool isBatch) internal returns (bytes memory) {
        (uint256 id, /* address sender */, /* address receiver */, bytes memory data) =
            abi.decode(input.unhashedLeaf, (uint256, address, address, bytes));
        if (isBatch) {
            if (_processedExits[id]) {
                return new bytes(0x00);
            }
        } else {
            require(!_processedExits[id], "EXIT_ALREADY_PROCESSED");
        }

        // slither-disable-next-line calls-loop
        require(
            _checkpointManager.getEventMembershipByBlockNumber(
                input.blockNumber, keccak256(input.unhashedLeaf), input.leafIndex, input.proof
            ),
            "INVALID_PROOF"
        );

        _processedExits[id] = true;

        emit ExitProcessed(id, true, data);

        return data;
    }

    function _submitCheckpoint(bytes calldata checkpointData) internal returns (ICheckpointManager.Checkpoint memory) {
        (
            uint256[2] memory signature,
            bytes memory bitmap,
            uint256 epochNumber,
            uint256 blockNumber,
            bytes32 blockHash,
            uint256 blockRound,
            bytes32 currentValidatorSetHash,
            bytes32 eventRoot
        ) = abi.decode(checkpointData, (uint256[2], bytes, uint256, uint256, bytes32, uint256, bytes32, bytes32));
        ICheckpointManager.Checkpoint memory checkpoint =
            ICheckpointManager.Checkpoint(epochNumber, blockNumber, eventRoot);
        _checkpointManager.submit(
            ICheckpointManager.CheckpointMetadata(blockHash, blockRound, currentValidatorSetHash),
            checkpoint,
            signature,
            new ICheckpointManager.Validator[](0), // TODO : add new validator set to the provider and pass it to here.
            bitmap
        );

        return checkpoint;
    }

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

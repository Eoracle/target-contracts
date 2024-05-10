// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ICheckpointManager } from "./interfaces/ICheckpointManager.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";

import { Merkle } from "./common/Merkle.sol";
import { FeedVerifierNotInitialized, ExitAlreadyProcessed, InvalidProof, InvalidAddress } from "./interfaces/Errors.sol";

using Merkle for bytes32;

contract EOFeedVerifier is IEOFeedVerifier, OwnableUpgradeable {
    mapping(uint256 => bool) internal _processedExits;
    ICheckpointManager internal _checkpointManager;

    modifier onlyInitialized() {
        if (address(_checkpointManager) == address(0)) revert FeedVerifierNotInitialized();
        _;
    }

    /**
     * @notice Initialize the contract with the checkpoint manager address
     * @dev The checkpoint manager contract must be deployed first
     * @param newCheckpointManager Address of the checkpoint manager contract
     * @param owner Owner of the contract
     */
    function initialize(ICheckpointManager newCheckpointManager, address owner) external initializer {
        if (address(newCheckpointManager) == address(0) || address(newCheckpointManager).code.length == 0) {
            revert InvalidAddress();
        }
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
     * @param checkpointMetadata Metadata for the checkpoint
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function submitAndExit(
        LeafInput calldata input,
        ICheckpointManager.CheckpointMetadata calldata checkpointMetadata,
        ICheckpointManager.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        onlyInitialized
        returns (bytes memory)
    {
        _checkpointManager.submit(
            checkpointMetadata,
            checkpoint,
            signature,
            new ICheckpointManager.Validator[](0), // TODO : add new validator set to the provider and pass it to here.
            bitmap
        );
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
     * @param checkpointMetadata Metadata for the checkpoint
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     * @return Array of the leaf data fields of all submitted leaves
     */
    function submitAndBatchExit(
        LeafInput[] calldata inputs,
        ICheckpointManager.CheckpointMetadata calldata checkpointMetadata,
        ICheckpointManager.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        onlyInitialized
        returns (bytes[] memory)
    {
        _checkpointManager.submit(
            checkpointMetadata,
            checkpoint,
            signature,
            new ICheckpointManager.Validator[](0), // TODO : add new validator set to the provider and pass it to here.
            bitmap
        );
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
        for (uint256 i = 0; i < length; i++) {
            returnData[i] = _exit(inputs[i], true);
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
            if (_processedExits[id]) revert ExitAlreadyProcessed();
        }

        // slither-disable-next-line calls-loop
        if (
            !_checkpointManager.getEventMembershipByBlockNumber(
                input.blockNumber, keccak256(input.unhashedLeaf), input.leafIndex, input.proof
            )
        ) revert InvalidProof();

        _processedExits[id] = true;

        emit ExitProcessed(id, true, data);

        return data;
    }

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

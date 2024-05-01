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
    address internal _feedRegistry;

    modifier onlyInitialized() {
        require(address(_checkpointManager) != address(0), "EOFeedVerifier: NOT_INITIALIZED");

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
            "ExitHelper: INVALID_ADDRESS"
        );
        _checkpointManager = newCheckpointManager;
        __Ownable_init(owner);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function exit(
        uint256 blockNumber,
        uint256 leafIndex,
        bytes calldata unhashedLeaf,
        bytes32[] calldata proof
    )
        external
        onlyInitialized
    {
        _exit(blockNumber, leafIndex, unhashedLeaf, proof, false);
    }

    /**
     * @notice Set the address of the feed registry contract
     * @param feedRegistry Address of the feed registry contract
     */
    function setFeedRegistry(address feedRegistry) external onlyOwner {
        _feedRegistry = feedRegistry;
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function submitAndExit(bytes calldata proofData) external onlyInitialized {
        (
            uint256[2] memory signature,
            bytes memory bitmap,
            bytes memory unhashedLeaf,
            uint256 leafIndex,
            uint256 epochNumber,
            uint256 blockNumber,
            bytes32 blockHash,
            uint256 blockRound,
            bytes32 currentValidatorSetHash,
            bytes32 eventRoot,
            bytes32[] memory proof
        ) = abi.decode(
            proofData,
            (uint256[2], bytes, bytes, uint256, uint256, uint256, bytes32, uint256, bytes32, bytes32, bytes32[])
        );

        _checkpointManager.submit(
            ICheckpointManager.CheckpointMetadata(blockHash, blockRound, currentValidatorSetHash),
            ICheckpointManager.Checkpoint(epochNumber, blockNumber, eventRoot),
            signature,
            new ICheckpointManager.Validator[](0), // TODO : add new validator set to the provider and pass it to here.
            bitmap
        );

        // COPY PASTE from _exit function
        // slither-disable-next-line calls-loop
        require(
            _checkpointManager.checkEventMembership(eventRoot, keccak256(unhashedLeaf), leafIndex, proof),
            "ExitHelper: INVALID_PROOF"
        );

        (uint256 id, /* address sender */, /* address receiver */, bytes memory data) =
            abi.decode(unhashedLeaf, (uint256, address, address, bytes));
        _processedExits[id] = true;

        emit ExitProcessed(id, true, data);
    }

    /**
     * @notice Perform a batch exit for multiple events
     * @param inputs Batch exit inputs for multiple event leaves
     */
    function batchExit(BatchExitInput[] calldata inputs) external onlyInitialized {
        uint256 length = inputs.length;

        for (uint256 i = 0; i < length;) {
            _exit(inputs[i].blockNumber, inputs[i].leafIndex, inputs[i].unhashedLeaf, inputs[i].proof, true);
            unchecked {
                ++i;
            }
        }
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
     * @notice Get the address of the feed registry contract
     * @return Address of the feed registry contract
     */
    function getFeedRegistry() external view returns (address) {
        return _feedRegistry;
    }

    /**
     * @notice Process an exit for one event
     * @param blockNumber Block number of the exit event on L2
     * @param leafIndex Index of the leaf in the exit event Merkle tree
     * @param unhashedLeaf ABI-encoded exit event leaf
     * @param proof Proof of the event inclusion in the tree
     * @param isBatch Boolean value indicating if the exit is part of a batch
     */
    function _exit(
        uint256 blockNumber,
        uint256 leafIndex,
        bytes calldata unhashedLeaf,
        bytes32[] calldata proof,
        bool isBatch
    )
        internal
    {
        (uint256 id, /* address sender */, /* address receiver */, bytes memory data) =
            abi.decode(unhashedLeaf, (uint256, address, address, bytes));
        if (isBatch) {
            if (_processedExits[id]) {
                return;
            }
        } else {
            require(!_processedExits[id], "ExitHelper: EXIT_ALREADY_PROCESSED");
        }

        // slither-disable-next-line calls-loop
        require(
            _checkpointManager.getEventMembershipByBlockNumber(blockNumber, keccak256(unhashedLeaf), leafIndex, proof),
            "ExitHelper: INVALID_PROOF"
        );

        _processedExits[id] = true;

        emit ExitProcessed(id, true, data);
    }

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

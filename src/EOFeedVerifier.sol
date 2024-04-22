// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ICheckpointManager } from "./interfaces/ICheckpointManager.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";

import { Merkle } from "./common/Merkle.sol";

using Merkle for bytes32;

contract EOFeedVerifier is IEOFeedVerifier, OwnableUpgradeable {
    mapping(uint256 => bool) public processedExits;
    ICheckpointManager public checkpointManager;
    address public feedRegistry;

    event ExitProcessed(uint256 indexed id, bool indexed success, bytes returnData);

    modifier onlyInitialized() {
        require(address(checkpointManager) != address(0), "ExitHelper: NOT_INITIALIZED");

        _;
    }

    /**
     * @notice Initialize the contract with the checkpoint manager address
     * @dev The checkpoint manager contract must be deployed first
     * @param newCheckpointManager Address of the checkpoint manager contract
     */
    function initialize(ICheckpointManager newCheckpointManager) external initializer {
        require(
            address(newCheckpointManager) != address(0) && address(newCheckpointManager).code.length != 0,
            "ExitHelper: INVALID_ADDRESS"
        );
        checkpointManager = newCheckpointManager;
        __Ownable_init(msg.sender);
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

    function setFeedRegistry(address _feedRegistry) external onlyOwner {
        feedRegistry = _feedRegistry;
    }

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

        checkpointManager.submit(
            ICheckpointManager.CheckpointMetadata(blockHash, blockRound, currentValidatorSetHash),
            ICheckpointManager.Checkpoint(epochNumber, blockNumber, eventRoot),
            signature,
            new ICheckpointManager.Validator[](0), // TODO : add new validator set to the provider and pass it to here.
            bitmap
        );

        // COPY PASTE from _exit function
        // slither-disable-next-line calls-loop
        require(
            checkpointManager.checkEventMembership(eventRoot, keccak256(unhashedLeaf), leafIndex, proof),
            "ExitHelper: INVALID_PROOF"
        );

        (uint256 id, /* address sender */, /* address receiver */, bytes memory data) =
            abi.decode(unhashedLeaf, (uint256, address, address, bytes));
        processedExits[id] = true;

        emit ExitProcessed(id, true, data);
    }

    /**
     * @inheritdoc IEOFeedVerifier
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
            if (processedExits[id]) {
                return;
            }
        } else {
            require(!processedExits[id], "ExitHelper: EXIT_ALREADY_PROCESSED");
        }

        // slither-disable-next-line calls-loop
        require(
            checkpointManager.getEventMembershipByBlockNumber(blockNumber, keccak256(unhashedLeaf), leafIndex, proof),
            "ExitHelper: INVALID_PROOF"
        );

        processedExits[id] = true;

        emit ExitProcessed(id, true, data);
    }

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

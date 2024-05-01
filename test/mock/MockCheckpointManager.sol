// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ICheckpointManager } from "../../src/interfaces/ICheckpointManager.sol";

contract MockCheckpointManager is ICheckpointManager {
    Checkpoint[] public checkpoints;
    CheckpointMetadata[] public checkpointMetadata;
    uint256[] public checkpointBlockNumbers;
    mapping(uint256 => bool) public eventMembership;
    mapping(uint256 => bytes32) public eventRootByBlock;
    Validator[] public validatorSet;

    function submit(
        CheckpointMetadata calldata _checkpointMetadata,
        Checkpoint calldata _checkpoint,
        uint256[2] calldata, /*signature*/
        Validator[] calldata, /*_newValidatorSet*/
        bytes calldata /*_bitmap*/
    )
        external
    {
        checkpoints.push(_checkpoint);
        checkpointMetadata.push(_checkpointMetadata);
        checkpointBlockNumbers.push(_checkpoint.blockNumber);
    }

    function setNewValidatorSet(Validator[] calldata newValidatorSet) external {
        delete validatorSet;
        for (uint256 i = 0; i < newValidatorSet.length; i++) {
            validatorSet.push(newValidatorSet[i]);
        }
    }

    function getEventMembershipByBlockNumber(
        uint256 _blockNumber,
        bytes32, /* _leaf */
        uint256, /*_leafIndex */
        bytes32[] memory /*_proof */
    )
        external
        view
        override
        returns (bool)
    {
        return eventMembership[_blockNumber];
    }

    function getEventMembershipByEpoch(
        uint256 epoch,
        bytes32, /*leaf*/
        uint256, /*leafIndex*/
        bytes32[] calldata /*proof*/
    )
        external
        view
        returns (bool)
    {
        return eventMembership[epoch];
    }

    function getCheckpointBlock(uint256 blockNumber) external view returns (bool, uint256) {
        for (uint256 i = 0; i < checkpointBlockNumbers.length; i++) {
            if (checkpointBlockNumbers[i] >= blockNumber) {
                return (true, checkpointBlockNumbers[i]);
            }
        }
        return (false, 0);
    }

    function getEventRootByBlock(uint256 blockNumber) external view returns (bytes32) {
        return eventRootByBlock[blockNumber];
    }

    function checkEventMembership(
        bytes32, /* eventRoot */
        bytes32, /* leaf */
        uint256, /* leafIndex */
        bytes32[] calldata /* proof */
    )
        external
        pure
        returns (bool)
    {
        return true;
    }
}

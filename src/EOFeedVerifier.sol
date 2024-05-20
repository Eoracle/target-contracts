// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";
import { Merkle } from "./common/Merkle.sol";
import {
    FeedVerifierNotInitialized,
    InvalidProof,
    InvalidAddress,
    InvalidEventRoot,
    VotingPowerIsZero,
    AggVotingPowerIsZero,
    InsufficientVotingPower,
    SignatureVerficationFailed
} from "./interfaces/Errors.sol";
import { IBLS } from "./interfaces/IBLS.sol";
import { IBN256G2 } from "./interfaces/IBN256G2.sol";

using Merkle for bytes32;

contract EOFeedVerifier is IEOFeedVerifier, OwnableUpgradeable {
    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");

    uint256 public childChainId;
    IBLS public bls;
    IBN256G2 public bn256G2;
    uint256 public currentValidatorSetLength;
    uint256 public totalVotingPower;
    mapping(uint256 => Validator) public currentValidatorSet;
    bytes32 public currentValidatorSetHash;

    modifier onlyInitialized() {
        if (_getInitializedVersion() == 0) revert FeedVerifierNotInitialized();
        _;
    }

    /**
     * @param owner Owner of the contract
     * @param _bls Address of the BLS library contract
     * @param _bn256G2 Address of the Bn256G2 library contract
     * @param _childChainId Chain ID of the child chain
     */
    function initialize(address owner, IBLS _bls, IBN256G2 _bn256G2, uint256 _childChainId) external initializer {
        if (
            address(_bls) == address(0) || address(_bls).code.length == 0 || address(_bn256G2) == address(0)
                || address(_bn256G2).code.length == 0
        ) {
            revert InvalidAddress();
        }
        childChainId = _childChainId;
        bls = _bls;
        bn256G2 = _bn256G2;
        __Ownable_init(owner);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     * @notice Function to set a new validator set for the CheckpointManager
     * @param newValidatorSet The new validator set to store
     */
    function setNewValidatorSet(Validator[] calldata newValidatorSet) public override onlyOwner {
        uint256 length = newValidatorSet.length;
        currentValidatorSetLength = length;
        currentValidatorSetHash = keccak256(abi.encode(newValidatorSet));
        uint256 totalPower = 0;
        for (uint256 i = 0; i < length; i++) {
            uint256 votingPower = newValidatorSet[i].votingPower;
            if (votingPower == 0) revert VotingPowerIsZero();
            totalPower += votingPower;
            currentValidatorSet[i] = newValidatorSet[i];
        }
        totalVotingPower = totalPower;
        emit ValidatorSetUpdated(currentValidatorSetLength, currentValidatorSetHash, totalVotingPower);
    }

    /**
     * @notice Verify a batch of exits leaves
     * @param inputs Batch exit inputs for multiple event leaves
     * @param eventRoot the root this event should belong to
     * @return Array of the leaf data fields of all submitted leaves
     */
    function verifyLeaves(LeafInput[] calldata inputs, bytes32 eventRoot) public returns (bytes[] memory) {
        uint256 length = inputs.length;
        bytes[] memory returnData = new bytes[](length);
        for (uint256 i = 0; i < length; i++) {
            returnData[i] = verifyLeaf(inputs[i], eventRoot);
        }
        return returnData;
    }

    /**
     * @notice Verify for one event
     * @param input Exit leaf input
     * @param eventRoot event root the leaf should belong to
     * @return The leaf data field
     */
    function verifyLeaf(LeafInput calldata input, bytes32 eventRoot) public returns (bytes memory) {
        bytes32 leaf = keccak256(input.unhashedLeaf);
        if (!leaf.checkMembership(input.leafIndex, eventRoot, input.proof)) {
            revert InvalidProof();
        }

        (uint256 id, /* address sender */, /* address receiver */, bytes memory data) =
            abi.decode(input.unhashedLeaf, (uint256, address, address, bytes));

        emit LeafVerified(id, data);

        return data;
    }

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
        public
        view
    {
        if (checkpoint.eventRoot == bytes32(0)) revert InvalidEventRoot();
        bytes memory hash = abi.encode(
            keccak256(
                // solhint-disable-next-line func-named-parameters
                abi.encode(
                    childChainId,
                    checkpoint.blockNumber,
                    checkpoint.blockHash,
                    checkpoint.blockRound,
                    checkpoint.epoch,
                    checkpoint.eventRoot,
                    currentValidatorSetHash,
                    currentValidatorSetHash
                )
            )
        );

        uint256[2] memory message = bls.hashToPoint(DOMAIN, hash);

        uint256 length = currentValidatorSetLength;
        // slither-disable-next-line uninitialized-local
        uint256[4] memory aggPubkey;
        uint256 aggVotingPower = 0;
        for (uint256 i = 0; i < length; i++) {
            if (_getValueFromBitmap(bitmap, i)) {
                if (aggVotingPower == 0) {
                    aggPubkey = currentValidatorSet[i].blsKey;
                } else {
                    uint256[4] memory blsKey = currentValidatorSet[i].blsKey;
                    // slither-disable-next-line calls-loop
                    (aggPubkey[0], aggPubkey[1], aggPubkey[2], aggPubkey[3]) = bn256G2.ecTwistAdd({
                        pt1xx: aggPubkey[0],
                        pt1xy: aggPubkey[1],
                        pt1yx: aggPubkey[2],
                        pt1yy: aggPubkey[3],
                        pt2xx: blsKey[0],
                        pt2xy: blsKey[1],
                        pt2yx: blsKey[2],
                        pt2yy: blsKey[3]
                    });
                }
                aggVotingPower += currentValidatorSet[i].votingPower;
            }
        }

        if (aggVotingPower == 0) revert AggVotingPowerIsZero();
        if (aggVotingPower <= ((2 * totalVotingPower) / 3)) revert InsufficientVotingPower();

        (bool callSuccess, bool result) = bls.verifySingle(signature, aggPubkey, message);

        if (!callSuccess || !result) revert SignatureVerficationFailed();
    }

    /**
     * @dev Extracts a boolean value from a specific index in a bitmap.
     * @param bitmap The bytes array containing the bitmap.
     * @param index The bit position from which to retrieve the value.
     * @return bool The boolean value of the bit at the specified index in the bitmap.
     *              Returns 'true' if the bit is set (1), and 'false' if the bit is not set (0).
     */
    function _getValueFromBitmap(bytes calldata bitmap, uint256 index) private pure returns (bool) {
        uint256 byteNumber = index / 8;
        uint8 bitNumber = uint8(index % 8);

        if (byteNumber >= bitmap.length) {
            return false;
        }

        // Get the value of the bit at the given 'index' in a byte.
        return uint8(bitmap[byteNumber]) & (1 << bitNumber) > 0;
    }

    // slither-disable-start unused-state
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
    // slither-disable-end unused-state
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";
import { Merkle } from "./common/Merkle.sol";
import {
    CallerIsNotFeedManager,
    InvalidProof,
    InvalidAddress,
    InvalidEventRoot,
    VotingPowerIsZero,
    AggVotingPowerIsZero,
    InsufficientVotingPower,
    SignatureVerificationFailed,
    ValidatorIndexOutOfBounds,
    SenderNotAllowed,
    ValidatorSetTooSmall
} from "./interfaces/Errors.sol";
import { IBLS } from "./interfaces/IBLS.sol";
import { IBN256G2 } from "./interfaces/IBN256G2.sol";

using Merkle for bytes32;

/**
 * @title EOFeedManager
 * @notice The EOFeedVerifier contract handles the verification of update payloads. The payload includes a Merkle root
 * signed by eoracle validators and a Merkle path to the leaf containing the data. The verifier stores the current
 * validator set in its storage and ensures that the Merkle root is signed by a subset of this validator set with
 * sufficient voting power.
 */
contract EOFeedVerifier is IEOFeedVerifier, OwnableUpgradeable {
    bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
    uint256 public constant MIN_VALIDATORS = 3;
    /// @dev ID of eoracle chain
    uint256 internal _eoracleChainId;

    /// @dev BLS library contract
    IBLS internal _bls;

    /// @dev BN256G2 library contract
    IBN256G2 internal _bn256G2;

    /// @dev length of validators set
    uint256 internal _currentValidatorSetLength;

    /// @dev total voting power of the current validators set
    uint256 internal _totalVotingPower;

    /// @dev current validators set (index => Validator)
    mapping(uint256 => Validator) internal _currentValidatorSet;

    /// @dev hash (keccak256) of the current validator set
    bytes32 internal _currentValidatorSetHash;

    /// @dev block number of the last processed block
    uint256 internal _lastProcessedBlockNumber;

    /// @dev event root of the last processed block
    bytes32 internal _lastProcessedEventRoot;

    /// @dev address of the feed manager
    address internal _feedManager;

    /// @dev mapping of allowed senders
    mapping(address => bool) internal _allowedSenders;

    /**
     * @dev Allows only the feed manager to call the function
     */
    modifier onlyFeedManager() {
        if (msg.sender != _feedManager) revert CallerIsNotFeedManager();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @param owner Owner of the contract
     * @param bls_ Address of the BLS library contract
     * @param bn256G2_ Address of the Bn256G2 library contract
     * @param eoracleChainId_ Chain ID of the eoracle chain
     * @param allowedSenders List of allowed senders
     */
    function initialize(
        address owner,
        IBLS bls_,
        IBN256G2 bn256G2_,
        uint256 eoracleChainId_,
        address[] calldata allowedSenders
    )
        external
        initializer
    {
        if (
            address(bls_) == address(0) || address(bls_).code.length == 0 || address(bn256G2_) == address(0)
                || address(bn256G2_).code.length == 0
        ) {
            revert InvalidAddress();
        }
        _eoracleChainId = eoracleChainId_;
        _bls = bls_;
        _bn256G2 = bn256G2_;
        _setAllowedSenders(allowedSenders, true);
        __Ownable_init(owner);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function verify(
        LeafInput calldata input,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        onlyFeedManager
        returns (bytes memory)
    {
        _processCheckpoint(checkpoint, signature, bitmap);
        bytes memory data = _verifyLeaf(input, checkpoint.eventRoot);
        return data;
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function batchVerify(
        LeafInput[] calldata inputs,
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        external
        onlyFeedManager
        returns (bytes[] memory)
    {
        _processCheckpoint(checkpoint, signature, bitmap);
        return _verifyLeaves(inputs, checkpoint.eventRoot);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function setNewValidatorSet(Validator[] calldata newValidatorSet) external onlyOwner {
        uint256 length = newValidatorSet.length;
        if (length < MIN_VALIDATORS) revert ValidatorSetTooSmall();
        // delete the slots of the old validators
        if (length < _currentValidatorSetLength) {
            for (uint256 i = length; i < _currentValidatorSetLength; i++) {
                delete _currentValidatorSet[i];
            }
        }
        _currentValidatorSetLength = length;
        _currentValidatorSetHash = keccak256(abi.encode(newValidatorSet));
        uint256 totalPower = 0;
        for (uint256 i = 0; i < length; i++) {
            if (newValidatorSet[i]._address == address(0)) revert InvalidAddress();
            uint256 votingPower = newValidatorSet[i].votingPower;
            if (votingPower == 0) revert VotingPowerIsZero();
            totalPower += votingPower;
            _currentValidatorSet[i] = newValidatorSet[i];
        }
        _totalVotingPower = totalPower;
        emit ValidatorSetUpdated(_currentValidatorSetLength, _currentValidatorSetHash, _totalVotingPower);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function setAllowedSenders(address[] calldata senders, bool allowed) external onlyOwner {
        _setAllowedSenders(senders, allowed);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function setFeedManager(address feedManager_) external onlyOwner {
        if (feedManager_ == address(0)) revert InvalidAddress();
        _feedManager = feedManager_;
        emit FeedManagerSet(feedManager_);
    }

    /**
     * @notice Set the bn256G2 contract
     * @param bn256G2_ Address of the BN256G2 contract
     */
    function setBN256G2(IBN256G2 bn256G2_) external onlyOwner {
        if (address(bn256G2_) == address(0) || address(bn256G2_).code.length == 0) {
            revert InvalidAddress();
        }
        _bn256G2 = bn256G2_;
    }

    /**
     * @notice Set the BLS contract
     * @param bls_ Address of the BLS contract
     */
    function setBLS(IBLS bls_) external onlyOwner {
        if (address(bls_) == address(0) || address(bls_).code.length == 0) {
            revert InvalidAddress();
        }
        _bls = bls_;
    }

    /**
     * @notice Returns the ID of the eoracle chain.
     * @return The eoracle chain ID.
     */
    function eoracleChainId() external view returns (uint256) {
        return _eoracleChainId;
    }

    /**
     * @notice Returns the BLS contract.
     * @return The BLS contract.
     */
    function bls() external view returns (IBLS) {
        return _bls;
    }

    /**
     * @notice Returns the BN256G2 contract.
     * @return The BN256G2 contract.
     */
    function bn256G2() external view returns (IBN256G2) {
        return _bn256G2;
    }

    /**
     * @notice Returns the length of the current validator set.
     * @return The number of validators in the current set.
     */
    function currentValidatorSetLength() external view returns (uint256) {
        return _currentValidatorSetLength;
    }

    /**
     * @notice Returns the total voting power of the current validator set.
     * @return The total voting power.
     */
    function totalVotingPower() external view returns (uint256) {
        return _totalVotingPower;
    }

    /**
     * @notice Returns the validator at the specified index in the current validator set.
     * @param index The index of the validator in the current set.
     * @return The validator at the given index.
     */
    function currentValidatorSet(uint256 index) external view returns (Validator memory) {
        if (index >= _currentValidatorSetLength) revert ValidatorIndexOutOfBounds();
        return _currentValidatorSet[index];
    }

    /**
     * @notice Returns the hash of the current validator set.
     * @return The hash of the current validator set.
     */
    function currentValidatorSetHash() external view returns (bytes32) {
        return _currentValidatorSetHash;
    }

    /**
     * @notice Returns the block number of the last processed block.
     * @return The last processed block number.
     */
    function lastProcessedBlockNumber() external view returns (uint256) {
        return _lastProcessedBlockNumber;
    }

    /**
     * @notice Returns the event root of the last processed block.
     * @return The last processed event root.
     */
    function lastProcessedEventRoot() external view returns (bytes32) {
        return _lastProcessedEventRoot;
    }

    /**
     * @notice Returns the address of the feed manager.
     * @return The address of the feed manager.
     */
    function feedManager() external view returns (address) {
        return _feedManager;
    }

    /**
     * @notice Returns whether the sender is allowed to submit leaves.
     * @param sender The address of the sender.
     */
    function isSenderAllowed(address sender) external view returns (bool) {
        return _allowedSenders[sender];
    }

    /**
     * @notice Function to verify the checkpoint signature
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function _processCheckpoint(
        IEOFeedVerifier.Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        internal
    {
        // if the eventRoot has not changed, we don't need to verify the whole checkpoint again
        if (checkpoint.eventRoot == _lastProcessedEventRoot) {
            return;
        }
        _verifySignature(checkpoint, signature, bitmap);
        if (checkpoint.blockNumber > _lastProcessedBlockNumber) {
            _lastProcessedBlockNumber = checkpoint.blockNumber;
            _lastProcessedEventRoot = checkpoint.eventRoot;
        }
    }

    function _setAllowedSenders(address[] calldata senders, bool allowed) internal {
        for (uint256 i; i < senders.length; i++) {
            _allowedSenders[senders[i]] = allowed;
        }
    }

    /**
     * @notice Verify the signature of the checkpoint
     * @param checkpoint Checkpoint data
     * @param signature Aggregated signature of the checkpoint
     * @param bitmap Bitmap of the validators who signed the checkpoint
     */
    function _verifySignature(
        Checkpoint calldata checkpoint,
        uint256[2] calldata signature,
        bytes calldata bitmap
    )
        internal
        view
    {
        if (checkpoint.eventRoot == bytes32(0)) revert InvalidEventRoot();
        bytes memory hash = abi.encode(
            keccak256(
                // solhint-disable-next-line func-named-parameters
                abi.encode(
                    _eoracleChainId,
                    checkpoint.blockNumber,
                    checkpoint.blockHash,
                    checkpoint.blockRound,
                    checkpoint.epoch,
                    checkpoint.eventRoot,
                    _currentValidatorSetHash,
                    _currentValidatorSetHash
                )
            )
        );

        uint256[2] memory message = _bls.hashToPoint(DOMAIN, hash);

        uint256 length = _currentValidatorSetLength;
        // slither-disable-next-line uninitialized-local
        uint256[4] memory aggPubkey;
        uint256 aggVotingPower = 0;
        for (uint256 i = 0; i < length; i++) {
            if (_getValueFromBitmap(bitmap, i)) {
                if (aggVotingPower == 0) {
                    aggPubkey = _currentValidatorSet[i].blsKey;
                } else {
                    uint256[4] memory blsKey = _currentValidatorSet[i].blsKey;
                    (aggPubkey[0], aggPubkey[1], aggPubkey[2], aggPubkey[3]) = _bn256G2.ecTwistAdd({
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
                aggVotingPower += _currentValidatorSet[i].votingPower;
            }
        }

        if (aggVotingPower == 0) revert AggVotingPowerIsZero();
        if (aggVotingPower <= ((2 * _totalVotingPower) / 3)) revert InsufficientVotingPower();

        (bool callSuccess, bool result) = _bls.verifySingle(signature, aggPubkey, message);

        if (!callSuccess || !result) revert SignatureVerificationFailed();
    }

    /**
     * @notice Verify a batch of exits leaves
     * @param inputs Batch exit inputs for multiple event leaves
     * @param eventRoot the root this event should belong to
     * @return Array of the leaf data fields of all submitted leaves
     */
    function _verifyLeaves(LeafInput[] calldata inputs, bytes32 eventRoot) internal view returns (bytes[] memory) {
        uint256 length = inputs.length;
        bytes[] memory returnData = new bytes[](length);
        for (uint256 i = 0; i < length; i++) {
            returnData[i] = _verifyLeaf(inputs[i], eventRoot);
        }
        return returnData;
    }

    /**
     * @notice Verify for one event
     * @param input Exit leaf input
     * @param eventRoot event root the leaf should belong to
     * @return The leaf data field
     */
    function _verifyLeaf(LeafInput calldata input, bytes32 eventRoot) internal view returns (bytes memory) {
        bytes32 leaf = keccak256(input.unhashedLeaf);
        if (!leaf.checkMembership(input.leafIndex, eventRoot, input.proof)) {
            revert InvalidProof();
        }

        ( /* uint256 id */ , address sender, /* address receiver */, bytes memory data) =
            abi.decode(input.unhashedLeaf, (uint256, address, address, bytes));
        if (!_allowedSenders[sender]) {
            revert SenderNotAllowed(sender);
        }

        return data;
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
        // safe to downcast as any value % 8 will always be less than 8
        uint8 bitNumber = uint8(index % 8);

        if (byteNumber >= bitmap.length) {
            return false;
        }
        // safe to downcast as bitmap[byteNumber] is byte and less than 256
        return uint8(bitmap[byteNumber]) & (1 << bitNumber) > 0;
    }

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line ordering
    uint256[50] private __gap;
}

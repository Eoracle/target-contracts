// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { IEOFeedVerifier } from "./interfaces/IEOFeedVerifier.sol";
import { Merkle } from "./common/Merkle.sol";
import { IBLS } from "./interfaces/IBLS.sol";
import { IBN256G2 } from "./interfaces/IBN256G2.sol";

// solhint-disable no-unused-import
import {
    CallerIsNotFeedManager,
    InvalidProof,
    InvalidAddress,
    InvalidEventRoot,
    VotingPowerIsZero,
    AggVotingPowerIsZero,
    InsufficientVotingPower,
    SignatureVerificationFailed,
    SignaturePairingFailed,
    ValidatorIndexOutOfBounds,
    ValidatorSetTooSmall
} from "./interfaces/Errors.sol";

/**
 * @title EOFeedManager
 * @notice The EOFeedVerifier contract handles the verification of update payloads. The payload includes a Merkle root
 * signed by eoracle validators and a Merkle path to the leaf containing the data. The verifier stores the current
 * validator set in its storage and ensures that the Merkle root is signed by a subset of this validator set with
 * sufficient voting power.
 */
contract EOFeedVerifier is IEOFeedVerifier, OwnableUpgradeable {
    using Merkle for bytes32;

    bytes32 public constant DOMAIN = keccak256("EORACLE_FEED_VERIFIER");

    uint256 internal _minNumOfValidators;

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

    uint256[2] internal _fullApk;

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
        _minNumOfValidators = 3;
        _setAllowedSenders(allowedSenders, true);
        __Ownable_init(owner);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function verify(
        LeafInput calldata input,
        VerificationParams calldata vParams
    )
        external
        onlyFeedManager
        returns (bytes memory)
    {
        _verifyVerificationParams(vParams);
        bytes memory data = _verifyLeaf(input, vParams.eventRoot);
        return data;
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function batchVerify(
        LeafInput[] calldata inputs,
        VerificationParams calldata vParams
    )
        external
        onlyFeedManager
        returns (bytes[] memory)
    {
        _verifyVerificationParams(vParams);
        return _verifyLeaves(inputs, vParams.eventRoot);
    }

    /**
     * @inheritdoc IEOFeedVerifier
     */
    function setNewValidatorSet(Validator[] calldata newValidatorSet) external onlyOwner {
        uint256 length = newValidatorSet.length;
        if (length < _minNumOfValidators) revert ValidatorSetTooSmall();
        // delete the slots of the old validators
        if (length < _currentValidatorSetLength) {
            for (uint256 i = length; i < _currentValidatorSetLength; i++) {
                delete _currentValidatorSet[i];
            }
        }
        _currentValidatorSetLength = length;
        _currentValidatorSetHash = keccak256(abi.encode(newValidatorSet));
        uint256 totalPower = 0;
        uint256[2] memory apk = [uint256(0), uint256(0)];
        for (uint256 i = 0; i < length; i++) {
            if (newValidatorSet[i]._address == address(0)) revert InvalidAddress();
            uint256 votingPower = newValidatorSet[i].votingPower;
            if (votingPower == 0) revert VotingPowerIsZero();
            totalPower += votingPower;
            _currentValidatorSet[i] = newValidatorSet[i];
            apk = _bls.ecadd(apk, newValidatorSet[i].g1pk);
        }
        _fullApk = apk;
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
     * @notice Returns the ID of the eoracle chain.
     * @return The eoracle chain ID.
     */
    function eoracleChainId() external view returns (uint256) {
        return _eoracleChainId;
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

    function bls() external view returns (IBLS) {
        return _bls;
    }

    function bn256G2() external view returns (IBN256G2) {
        return _bn256G2;
    }
    /**
     * @notice Function to verify the checkpoint signature
     * @param vParams Signed data
     */

    function _verifyVerificationParams(IEOFeedVerifier.VerificationParams calldata vParams) internal {
        // if the eventRoot has not changed, we don't need to verify the whole checkpoint again
        if (vParams.eventRoot == _lastProcessedEventRoot) {
            return;
        }

        _verifySignature(
            vParams.eventRoot, vParams.blockNumber, vParams.signature, vParams.apkG2, vParams.nonSignersBitmap
        );
        if (vParams.blockNumber > _lastProcessedBlockNumber) {
            _lastProcessedBlockNumber = vParams.blockNumber;
            _lastProcessedEventRoot = vParams.eventRoot;
        }
    }

    function _setAllowedSenders(address[] calldata senders, bool allowed) internal {
        for (uint256 i; i < senders.length; i++) {
            _allowedSenders[senders[i]] = allowed;
        }
    }

    /**
     * @notice Verify the signature of the checkpoint
     * @param eventRoot Root of the event
     * @param blockNumber Block number of the event
     * @param signature G1 Aggregated signature of the checkpoint
     * @param apkG2 G2 Aggregated public key of the checkpoint
     * @param nonSignersBitmap Bitmap of the validators who did not signed the data
     */
    function _verifySignature(
        bytes32 eventRoot,
        uint256 blockNumber,
        uint256[2] calldata signature,
        uint256[4] calldata apkG2,
        bytes calldata nonSignersBitmap
    )
        internal
        view
    {
        if (eventRoot == bytes32(0)) revert InvalidEventRoot();

        uint256[2] memory apk = [uint256(0), uint256(0)];
        uint256 aggVotingPower = _totalVotingPower;
        // first apk will hold all non signers
        for (uint256 i = 0; i < _currentValidatorSetLength; i++) {
            Validator memory v = _currentValidatorSet[i];
            if (_getValueFromBitmap(nonSignersBitmap, i)) {
                apk = _bls.ecadd(apk, v.g1pk);
                aggVotingPower -= v.votingPower;
            }
        }

        // we check the agg voting power is indeed sufficient
        if (aggVotingPower == 0) revert AggVotingPowerIsZero();
        if (aggVotingPower <= ((2 * _totalVotingPower) / 3)) revert InsufficientVotingPower();

        // then we negate the non signers and add the full apk
        apk = _bls.ecadd(_fullApk, _bls.neg(apk));
        uint256[2] memory msgHash =
            _bls.hashToPoint(DOMAIN, abi.encode(keccak256(abi.encodePacked(eventRoot, blockNumber))));
        (bool pairingSuccessful, bool signatureIsValid) =
            _bls.verifySignatureAndVeracity(apk, signature, msgHash, apkG2);
        // (bool pairingSuccessful, bool signatureIsValid) = _bls.verifySignature(signature, apkG2, msgG1);

        if (!pairingSuccessful) revert SignaturePairingFailed();
        if (!signatureIsValid) revert SignatureVerificationFailed();
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

        return input.unhashedLeaf;
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

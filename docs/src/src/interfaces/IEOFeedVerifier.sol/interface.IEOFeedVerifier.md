# IEOFeedVerifier

[Git Source](https://github.com/Eoracle/target-contracts/blob/f4fda3a61e4cccb09ed94cf04c4ed0f0b162d9e8/src/interfaces/IEOFeedVerifier.sol)

**Author:** Lightblocks

Helper contract to process state syncs from EOracle chain

## Functions

### verify

Verifies leaf

```solidity
function verify(
    LeafInput memory input,
    Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external
    returns (bytes memory leafData);
```

**Parameters**

| Name         | Type         | Description                                        |
| ------------ | ------------ | -------------------------------------------------- |
| `input`      | `LeafInput`  | Exit leaf input                                    |
| `checkpoint` | `Checkpoint` | Checkpoint data                                    |
| `signature`  | `uint256[2]` | Aggregated signature of the checkpoint             |
| `bitmap`     | `bytes`      | Bitmap of the validators who signed the checkpoint |

### batchVerify

Verifies multiple leaves

```solidity
function batchVerify(
    LeafInput[] memory inputs,
    Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external
    returns (bytes[] memory);
```

**Parameters**

| Name         | Type          | Description                                        |
| ------------ | ------------- | -------------------------------------------------- |
| `inputs`     | `LeafInput[]` | Exit leaves inputs                                 |
| `checkpoint` | `Checkpoint`  | Checkpoint data                                    |
| `signature`  | `uint256[2]`  | Aggregated signature of the checkpoint             |
| `bitmap`     | `bytes`       | Bitmap of the validators who signed the checkpoint |

### setNewValidatorSet

Function to set a new validator set for the CheckpointManager

```solidity
function setNewValidatorSet(Validator[] calldata newValidatorSet) external;
```

**Parameters**

| Name              | Type          | Description                    |
| ----------------- | ------------- | ------------------------------ |
| `newValidatorSet` | `Validator[]` | The new validator set to store |

## Events

### LeafVerified

```solidity
event LeafVerified(uint256 indexed id, bytes returnData);
```

### ValidatorSetUpdated

```solidity
event ValidatorSetUpdated(uint256 currentValidatorSetLength, bytes32 currentValidatorSetHash, uint256 totalVotingPower);
```

## Structs

### LeafInput

```solidity
struct LeafInput {
    uint256 leafIndex;
    bytes unhashedLeaf;
    bytes32[] proof;
}
```

### Checkpoint

```solidity
struct Checkpoint {
    uint256 epoch;
    uint256 blockNumber;
    bytes32 eventRoot;
    bytes32 blockHash;
    uint256 blockRound;
}
```

### Validator

```solidity
struct Validator {
    address _address;
    uint256[4] blsKey;
    uint256 votingPower;
}
```

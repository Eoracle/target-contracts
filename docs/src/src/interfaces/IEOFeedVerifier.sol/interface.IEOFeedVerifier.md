# IEOFeedVerifier

[Git Source](https://github.com/Eoracle/target-contracts/blob/2a1c0c442230a3038c84f19545812da920182a69/src/interfaces/IEOFeedVerifier.sol)

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

### setFeedManager

Sets the address of the feed manager.

```solidity
function setFeedManager(address feedManager) external;
```

**Parameters**

| Name          | Type      | Description                          |
| ------------- | --------- | ------------------------------------ |
| `feedManager` | `address` | The address of the new feed manager. |

## Events

### ValidatorSetUpdated

```solidity
event ValidatorSetUpdated(uint256 currentValidatorSetLength, bytes32 currentValidatorSetHash, uint256 totalVotingPower);
```

### FeedManagerSet

```solidity
event FeedManagerSet(address feedManager);
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

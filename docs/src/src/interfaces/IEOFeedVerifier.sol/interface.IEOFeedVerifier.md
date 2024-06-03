# IEOFeedVerifier

[Git Source](https://github.com/Eoracle/target-contracts/blob/de89fc9e9bc7c046937883aa064d90812f1542cc/src/interfaces/IEOFeedVerifier.sol)

## Functions

### verify

Verifies leaf, processes checkpoint, returns leaf data in case if checkpoint is valid and leaf is part of the merkle
tree

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
| `input`      | `LeafInput`  | leaf input data and proof (LeafInput)              |
| `checkpoint` | `Checkpoint` | Checkpoint data (Checkpoint)                       |
| `signature`  | `uint256[2]` | Aggregated signature of the checkpoint             |
| `bitmap`     | `bytes`      | Bitmap of the validators who signed the checkpoint |

**Returns**

| Name       | Type    | Description                                                             |
| ---------- | ------- | ----------------------------------------------------------------------- |
| `leafData` | `bytes` | Leaf data, abi encoded (uint16 feedId, uint256 rate, uint256 timestamp) |

### batchVerify

Verifies multiple leaves, processes checkpoint, returns leaf data in case if checkpoint is valid and leaves are part of
the merkle tree

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

Function to set a new validator set

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
function setFeedManager(address feedManager_) external;
```

**Parameters**

| Name           | Type      | Description                          |
| -------------- | --------- | ------------------------------------ |
| `feedManager_` | `address` | The address of the new feed manager. |

## Events

### ValidatorSetUpdated

_Event emitted when the validator set is updated_

```solidity
event ValidatorSetUpdated(uint256 currentValidatorSetLength, bytes32 currentValidatorSetHash, uint256 totalVotingPower);
```

**Parameters**

| Name                        | Type      | Description                                     |
| --------------------------- | --------- | ----------------------------------------------- |
| `currentValidatorSetLength` | `uint256` | Length of the current validator set             |
| `currentValidatorSetHash`   | `bytes32` | Hash of the current validator set               |
| `totalVotingPower`          | `uint256` | Total voting power of the current validator set |

### FeedManagerSet

_Event emitted when the feed manager is set_

```solidity
event FeedManagerSet(address feedManager);
```

**Parameters**

| Name          | Type      | Description                 |
| ------------- | --------- | --------------------------- |
| `feedManager` | `address` | Address of the feed manager |

## Structs

### LeafInput

_Leaf input structure_

```solidity
struct LeafInput {
    uint256 leafIndex;
    bytes unhashedLeaf;
    bytes32[] proof;
}
```

**Properties**

| Name           | Type        | Description                                                                                                                                                                             |
| -------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `leafIndex`    | `uint256`   | Index of the leaf                                                                                                                                                                       |
| `unhashedLeaf` | `bytes`     | Unhashed leaf data abi encoded (uint256 id, address sender, address receiver, bytes memory data) where bytes memory data = abi encoded (uint16 feedId, uint256 rate, uint256 timestamp) |
| `proof`        | `bytes32[]` | Merkle proof of the leaf                                                                                                                                                                |

### Checkpoint

_Checkpoint structure_

```solidity
struct Checkpoint {
    uint256 epoch;
    uint256 blockNumber;
    bytes32 eventRoot;
    bytes32 blockHash;
    uint256 blockRound;
}
```

**Properties**

| Name          | Type      | Description                   |
| ------------- | --------- | ----------------------------- |
| `epoch`       | `uint256` | Epoch number                  |
| `blockNumber` | `uint256` | Block number                  |
| `eventRoot`   | `bytes32` | Event root of the merkle tree |
| `blockHash`   | `bytes32` | Block hash                    |
| `blockRound`  | `uint256` | Block round                   |

### Validator

_Validator structure_

```solidity
struct Validator {
    address _address;
    uint256[4] blsKey;
    uint256 votingPower;
}
```

**Properties**

| Name          | Type         | Description            |
| ------------- | ------------ | ---------------------- |
| `_address`    | `address`    | Validator address      |
| `blsKey`      | `uint256[4]` | Validator BLS key      |
| `votingPower` | `uint256`    | Validator voting power |

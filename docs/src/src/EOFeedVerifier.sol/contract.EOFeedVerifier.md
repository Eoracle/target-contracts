# EOFeedVerifier

[Git Source](https://github.com/Eoracle/target-contracts/blob/ad9e9f7d406e96d8227780565e0953208bab6e55/src/EOFeedVerifier.sol)

**Inherits:** [IEOFeedVerifier](/src/interfaces/IEOFeedVerifier.sol/interface.IEOFeedVerifier.md), OwnableUpgradeable

## State Variables

### DOMAIN

```solidity
bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
```

### childChainId

```solidity
uint256 public childChainId;
```

### bls

```solidity
IBLS public bls;
```

### bn256G2

```solidity
IBN256G2 public bn256G2;
```

### currentValidatorSetLength

```solidity
uint256 public currentValidatorSetLength;
```

### totalVotingPower

```solidity
uint256 public totalVotingPower;
```

### currentValidatorSet

```solidity
mapping(uint256 => Validator) public currentValidatorSet;
```

### currentValidatorSetHash

```solidity
bytes32 public currentValidatorSetHash;
```

### \_\_gap

```solidity
uint256[50] private __gap;
```

## Functions

### onlyInitialized

```solidity
modifier onlyInitialized();
```

### initialize

```solidity
function initialize(address owner, IBLS _bls, IBN256G2 _bn256G2, uint256 _childChainId) external initializer;
```

**Parameters**

| Name            | Type       | Description                             |
| --------------- | ---------- | --------------------------------------- |
| `owner`         | `address`  | Owner of the contract                   |
| `_bls`          | `IBLS`     | Address of the BLS library contract     |
| `_bn256G2`      | `IBN256G2` | Address of the Bn256G2 library contract |
| `_childChainId` | `uint256`  | Chain ID of the child chain             |

### verify

Verifies leaf

```solidity
function verify(
    LeafInput calldata input,
    Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external
    onlyInitialized
    returns (bytes memory);
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
    LeafInput[] calldata inputs,
    Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    external
    onlyInitialized
    returns (bytes[] memory);
```

**Parameters**

| Name         | Type          | Description                                        |
| ------------ | ------------- | -------------------------------------------------- |
| `inputs`     | `LeafInput[]` | Batch exit inputs for multiple event leaves        |
| `checkpoint` | `Checkpoint`  | Checkpoint data                                    |
| `signature`  | `uint256[2]`  | Aggregated signature of the checkpoint             |
| `bitmap`     | `bytes`       | Bitmap of the validators who signed the checkpoint |

**Returns**

| Name     | Type      | Description                                           |
| -------- | --------- | ----------------------------------------------------- |
| `<none>` | `bytes[]` | Array of the leaf data fields of all submitted leaves |

### setNewValidatorSet

Function to set a new validator set for the CheckpointManager

```solidity
function setNewValidatorSet(Validator[] calldata newValidatorSet) public override onlyOwner;
```

**Parameters**

| Name              | Type          | Description                    |
| ----------------- | ------------- | ------------------------------ |
| `newValidatorSet` | `Validator[]` | The new validator set to store |

### \_verifyLeaves

Verify a batch of exits leaves

```solidity
function _verifyLeaves(LeafInput[] calldata inputs, bytes32 eventRoot) internal returns (bytes[] memory);
```

**Parameters**

| Name        | Type          | Description                                 |
| ----------- | ------------- | ------------------------------------------- |
| `inputs`    | `LeafInput[]` | Batch exit inputs for multiple event leaves |
| `eventRoot` | `bytes32`     | the root this event should belong to        |

**Returns**

| Name     | Type      | Description                                           |
| -------- | --------- | ----------------------------------------------------- |
| `<none>` | `bytes[]` | Array of the leaf data fields of all submitted leaves |

### \_verifyLeaf

Verify for one event

```solidity
function _verifyLeaf(LeafInput calldata input, bytes32 eventRoot) internal returns (bytes memory);
```

**Parameters**

| Name        | Type        | Description                          |
| ----------- | ----------- | ------------------------------------ |
| `input`     | `LeafInput` | Exit leaf input                      |
| `eventRoot` | `bytes32`   | event root the leaf should belong to |

**Returns**

| Name     | Type    | Description         |
| -------- | ------- | ------------------- |
| `<none>` | `bytes` | The leaf data field |

### \_verifySignature

Verify the signature of the checkpoint

```solidity
function _verifySignature(
    Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    internal
    view;
```

**Parameters**

| Name         | Type         | Description                                        |
| ------------ | ------------ | -------------------------------------------------- |
| `checkpoint` | `Checkpoint` | Checkpoint data                                    |
| `signature`  | `uint256[2]` | Aggregated signature of the checkpoint             |
| `bitmap`     | `bytes`      | Bitmap of the validators who signed the checkpoint |

### \_getValueFromBitmap

_Extracts a boolean value from a specific index in a bitmap._

```solidity
function _getValueFromBitmap(bytes calldata bitmap, uint256 index) private pure returns (bool);
```

**Parameters**

| Name     | Type      | Description                                        |
| -------- | --------- | -------------------------------------------------- |
| `bitmap` | `bytes`   | The bytes array containing the bitmap.             |
| `index`  | `uint256` | The bit position from which to retrieve the value. |

**Returns**

| Name     | Type   | Description                                                                                                                                          |
| -------- | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `<none>` | `bool` | bool The boolean value of the bit at the specified index in the bitmap. Returns 'true' if the bit is set (1), and 'false' if the bit is not set (0). |

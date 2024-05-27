# EOFeedVerifier

[Git Source](https://github.com/Eoracle/target-contracts/blob/836becbe8b5ae010bb5578a508ed70676be90884/src/EOFeedVerifier.sol)

**Inherits:** [IEOFeedVerifier](/src/interfaces/IEOFeedVerifier.sol/interface.IEOFeedVerifier.md), OwnableUpgradeable

## State Variables

### DOMAIN

```solidity
bytes32 public constant DOMAIN = keccak256("DOMAIN_CHECKPOINT_MANAGER");
```

### MAX_VALIDATORS

```solidity
uint256 public constant MAX_VALIDATORS = 256;
```

### \_eoracleChainId

```solidity
uint256 internal _eoracleChainId;
```

### \_bls

```solidity
IBLS internal _bls;
```

### \_bn256G2

```solidity
IBN256G2 internal _bn256G2;
```

### \_currentValidatorSetLength

```solidity
uint256 internal _currentValidatorSetLength;
```

### \_totalVotingPower

```solidity
uint256 internal _totalVotingPower;
```

### \_currentValidatorSet

```solidity
mapping(uint256 => Validator) internal _currentValidatorSet;
```

### \_currentValidatorSetHash

```solidity
bytes32 internal _currentValidatorSetHash;
```

### \_lastProcessedBlockNumber

```solidity
uint256 internal _lastProcessedBlockNumber;
```

### \_lastProcessedEventRoot

```solidity
bytes32 internal _lastProcessedEventRoot;
```

### \_feedManager

```solidity
address internal _feedManager;
```

### \_\_gap

```solidity
uint256[50] private __gap;
```

## Functions

### onlyFeedManager

```solidity
modifier onlyFeedManager();
```

### initialize

```solidity
function initialize(address owner, IBLS bls_, IBN256G2 bn256G2_, uint256 eoracleChainId_) external initializer;
```

**Parameters**

| Name              | Type       | Description                             |
| ----------------- | ---------- | --------------------------------------- |
| `owner`           | `address`  | Owner of the contract                   |
| `bls_`            | `IBLS`     | Address of the BLS library contract     |
| `bn256G2_`        | `IBN256G2` | Address of the Bn256G2 library contract |
| `eoracleChainId_` | `uint256`  | Chain ID of the eoracle chain           |

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
    onlyFeedManager
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
    onlyFeedManager
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

### setFeedManager

Sets the address of the feed manager.

```solidity
function setFeedManager(address feedManager_) external onlyOwner;
```

**Parameters**

| Name           | Type      | Description                          |
| -------------- | --------- | ------------------------------------ |
| `feedManager_` | `address` | The address of the new feed manager. |

### eoracleChainId

Returns the ID of the eoracle chain.

```solidity
function eoracleChainId() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description           |
| -------- | --------- | --------------------- |
| `<none>` | `uint256` | The eoracle chain ID. |

### bls

Returns the BLS contract.

```solidity
function bls() external view returns (IBLS);
```

**Returns**

| Name     | Type   | Description       |
| -------- | ------ | ----------------- |
| `<none>` | `IBLS` | The BLS contract. |

### bn256G2

Returns the BN256G2 contract.

```solidity
function bn256G2() external view returns (IBN256G2);
```

**Returns**

| Name     | Type       | Description           |
| -------- | ---------- | --------------------- |
| `<none>` | `IBN256G2` | The BN256G2 contract. |

### currentValidatorSetLength

Returns the length of the current validator set.

```solidity
function currentValidatorSetLength() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description                                  |
| -------- | --------- | -------------------------------------------- |
| `<none>` | `uint256` | The number of validators in the current set. |

### totalVotingPower

Returns the total voting power of the current validator set.

```solidity
function totalVotingPower() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description             |
| -------- | --------- | ----------------------- |
| `<none>` | `uint256` | The total voting power. |

### currentValidatorSet

Returns the validator at the specified index in the current validator set.

```solidity
function currentValidatorSet(uint256 index) external view returns (Validator memory);
```

**Parameters**

| Name    | Type      | Description                                    |
| ------- | --------- | ---------------------------------------------- |
| `index` | `uint256` | The index of the validator in the current set. |

**Returns**

| Name     | Type        | Description                       |
| -------- | ----------- | --------------------------------- |
| `<none>` | `Validator` | The validator at the given index. |

### currentValidatorSetHash

Returns the hash of the current validator set.

```solidity
function currentValidatorSetHash() external view returns (bytes32);
```

**Returns**

| Name     | Type      | Description                            |
| -------- | --------- | -------------------------------------- |
| `<none>` | `bytes32` | The hash of the current validator set. |

### lastProcessedBlockNumber

Returns the block number of the last processed block.

```solidity
function lastProcessedBlockNumber() external view returns (uint256);
```

**Returns**

| Name     | Type      | Description                      |
| -------- | --------- | -------------------------------- |
| `<none>` | `uint256` | The last processed block number. |

### lastProcessedEventRoot

Returns the event root of the last processed block.

```solidity
function lastProcessedEventRoot() external view returns (bytes32);
```

**Returns**

| Name     | Type      | Description                    |
| -------- | --------- | ------------------------------ |
| `<none>` | `bytes32` | The last processed event root. |

### feedManager

Returns the address of the feed manager.

```solidity
function feedManager() external view returns (address);
```

**Returns**

| Name     | Type      | Description                      |
| -------- | --------- | -------------------------------- |
| `<none>` | `address` | The address of the feed manager. |

### setNewValidatorSet

Function to set a new validator set for the CheckpointManager

```solidity
function setNewValidatorSet(Validator[] calldata newValidatorSet) public override onlyOwner;
```

**Parameters**

| Name              | Type          | Description                    |
| ----------------- | ------------- | ------------------------------ |
| `newValidatorSet` | `Validator[]` | The new validator set to store |

### \_processCheckpoint

Function to verify the checkpoint signature

```solidity
function _processCheckpoint(
    IEOFeedVerifier.Checkpoint calldata checkpoint,
    uint256[2] calldata signature,
    bytes calldata bitmap
)
    internal;
```

**Parameters**

| Name         | Type                         | Description                                        |
| ------------ | ---------------------------- | -------------------------------------------------- |
| `checkpoint` | `IEOFeedVerifier.Checkpoint` | Checkpoint data                                    |
| `signature`  | `uint256[2]`                 | Aggregated signature of the checkpoint             |
| `bitmap`     | `bytes`                      | Bitmap of the validators who signed the checkpoint |

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

### \_verifyLeaves

Verify a batch of exits leaves

```solidity
function _verifyLeaves(LeafInput[] calldata inputs, bytes32 eventRoot) internal pure returns (bytes[] memory);
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
function _verifyLeaf(LeafInput calldata input, bytes32 eventRoot) internal pure returns (bytes memory);
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

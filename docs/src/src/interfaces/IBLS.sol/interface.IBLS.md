# IBLS

[Git Source](https://github.com/Eoracle/target-contracts/blob/de89fc9e9bc7c046937883aa064d90812f1542cc/src/interfaces/IBLS.sol)

## Functions

### verifySingle

verifies a single signature

```solidity
function verifySingle(
    uint256[2] calldata signature,
    uint256[4] calldata pubkey,
    uint256[2] calldata message
)
    external
    view
    returns (bool, bool);
```

**Parameters**

| Name        | Type         | Description                            |
| ----------- | ------------ | -------------------------------------- |
| `signature` | `uint256[2]` | 64-byte G1 group element (small sig)   |
| `pubkey`    | `uint256[4]` | 128-byte G2 group element (big pubkey) |
| `message`   | `uint256[2]` | message signed to produce signature    |

**Returns**

| Name     | Type   | Description                  |
| -------- | ------ | ---------------------------- |
| `<none>` | `bool` | bool sig verification        |
| `<none>` | `bool` | bool indicating call success |

### verifyMultiple

verifies multiple non-aggregated signatures where each message is unique

```solidity
function verifyMultiple(
    uint256[2] calldata signature,
    uint256[4][] calldata pubkeys,
    uint256[2][] calldata messages
)
    external
    view
    returns (bool checkResult, bool callSuccess);
```

**Parameters**

| Name        | Type           | Description                                     |
| ----------- | -------------- | ----------------------------------------------- |
| `signature` | `uint256[2]`   | 64-byte G1 group element (small sig)            |
| `pubkeys`   | `uint256[4][]` | array of 128-byte G2 group element (big pubkey) |
| `messages`  | `uint256[2][]` | array of messages signed to produce signature   |

**Returns**

| Name          | Type   | Description                      |
| ------------- | ------ | -------------------------------- |
| `checkResult` | `bool` | bool indicating sig verification |
| `callSuccess` | `bool` | bool indicating call success     |

### verifyMultipleSameMsg

verifies an aggregated signature where the same message is signed

```solidity
function verifyMultipleSameMsg(
    uint256[2] calldata signature,
    uint256[4][] calldata pubkeys,
    uint256[2] calldata message
)
    external
    view
    returns (bool checkResult, bool callSuccess);
```

**Parameters**

| Name        | Type           | Description                                     |
| ----------- | -------------- | ----------------------------------------------- |
| `signature` | `uint256[2]`   | 64-byte G1 group element (small sig)            |
| `pubkeys`   | `uint256[4][]` | array of 128-byte G2 group element (big pubkey) |
| `message`   | `uint256[2]`   | message signed by all to produce signature      |

**Returns**

| Name          | Type   | Description             |
| ------------- | ------ | ----------------------- |
| `checkResult` | `bool` | sig verification        |
| `callSuccess` | `bool` | indicating call success |

### isValidSignature

checks if a signature is formatted correctly and valid

_will revert if improperly formatted, will return false if invalid_

```solidity
function isValidSignature(uint256[2] memory signature) external view returns (bool);
```

**Parameters**

| Name        | Type         | Description       |
| ----------- | ------------ | ----------------- |
| `signature` | `uint256[2]` | the BLS signature |

**Returns**

| Name     | Type   | Description                                      |
| -------- | ------ | ------------------------------------------------ |
| `<none>` | `bool` | bool indicating if the signature is valid or not |

### hashToPoint

hashes an arbitrary message to a point on the curve

_Fouque-Tibouchi Hash to Curve_

```solidity
function hashToPoint(bytes32 domain, bytes memory message) external view returns (uint256[2] memory);
```

**Parameters**

| Name      | Type      | Description                   |
| --------- | --------- | ----------------------------- |
| `domain`  | `bytes32` | domain separator for the hash |
| `message` | `bytes`   | the message to map            |

**Returns**

| Name     | Type         | Description                                                  |
| -------- | ------------ | ------------------------------------------------------------ |
| `<none>` | `uint256[2]` | uint256[2] (x,y) point on the curve that the message maps to |

### hashToField

hashes an arbitrary message to a field element

```solidity
function hashToField(bytes32 domain, bytes memory messages) external view returns (uint256[2] memory);
```

**Parameters**

| Name       | Type      | Description                   |
| ---------- | --------- | ----------------------------- |
| `domain`   | `bytes32` | domain separator for the hash |
| `messages` | `bytes`   | the messages to map           |

**Returns**

| Name     | Type         | Description                                                          |
| -------- | ------------ | -------------------------------------------------------------------- |
| `<none>` | `uint256[2]` | uint256[2] (x,y) point of the field element that the message maps to |

### mapToPoint

maps a field element to the curve

```solidity
function mapToPoint(uint256 _x) external pure returns (uint256[2] memory p);
```

**Parameters**

| Name | Type      | Description           |
| ---- | --------- | --------------------- |
| `_x` | `uint256` | a valid field element |

**Returns**

| Name | Type         | Description                                   |
| ---- | ------------ | --------------------------------------------- |
| `p`  | `uint256[2]` | the point on the curve the point is mapped to |

### isOnCurveG1

checks if point in the finite field Fq (x,y) is on the G1 curve

```solidity
function isOnCurveG1(uint256[2] memory point) external pure returns (bool _isOnCurve);
```

**Parameters**

| Name    | Type         | Description                            |
| ------- | ------------ | -------------------------------------- |
| `point` | `uint256[2]` | array with x and y values of the point |

**Returns**

| Name         | Type   | Description                                         |
| ------------ | ------ | --------------------------------------------------- |
| `_isOnCurve` | `bool` | bool indicating if the point is on the curve or not |

### isOnCurveG2

checks if point in the finite field Fq (x,y) is on the G2 curve

```solidity
function isOnCurveG2(uint256[4] memory point) external pure returns (bool _isOnCurve);
```

**Parameters**

| Name    | Type         | Description                            |
| ------- | ------------ | -------------------------------------- |
| `point` | `uint256[4]` | array with x and y values of the point |

**Returns**

| Name         | Type   | Description                                         |
| ------------ | ------ | --------------------------------------------------- |
| `_isOnCurve` | `bool` | bool indicating if the point is on the curve or not |

### expandMsgTo96

pads messages less than 96 bytes to 96 bytes for hashing

```solidity
function expandMsgTo96(bytes32 domain, bytes memory message) external pure returns (bytes memory);
```

**Parameters**

| Name      | Type      | Description                   |
| --------- | --------- | ----------------------------- |
| `domain`  | `bytes32` | domain separator for the hash |
| `message` | `bytes`   | the message to pad            |

**Returns**

| Name     | Type    | Description              |
| -------- | ------- | ------------------------ |
| `<none>` | `bytes` | bytes the padded message |

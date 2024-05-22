# BLS

[Git Source](https://github.com/Eoracle/target-contracts/blob/ad9e9f7d406e96d8227780565e0953208bab6e55/src/common/BLS.sol)

**Inherits:** [IBLS](/src/interfaces/IBLS.sol/interface.IBLS.md)

## State Variables

### N

```solidity
uint256 private constant N =
    21_888_242_871_839_275_222_246_405_745_257_275_088_696_311_157_297_823_662_689_037_894_645_226_208_583;
```

### N_G2_X1

```solidity
uint256 private constant N_G2_X1 =
    11_559_732_032_986_387_107_991_004_021_392_285_783_925_812_861_821_192_530_917_403_151_452_391_805_634;
```

### N_G2_X0

```solidity
uint256 private constant N_G2_X0 =
    10_857_046_999_023_057_135_944_570_762_232_829_481_370_756_359_578_518_086_990_519_993_285_655_852_781;
```

### N_G2_Y1

```solidity
uint256 private constant N_G2_Y1 =
    17_805_874_995_975_841_540_914_202_342_111_839_520_379_459_829_704_422_454_583_296_818_431_106_115_052;
```

### N_G2_Y0

```solidity
uint256 private constant N_G2_Y0 =
    13_392_588_948_715_843_804_641_432_497_768_002_650_278_120_570_034_223_513_918_757_245_338_268_106_653;
```

### Z0

```solidity
uint256 private constant Z0 = 0x0000000000000000b3c4d79d41a91759a9e4c7e359b6b89eaec68e62effffffd;
```

### Z1

```solidity
uint256 private constant Z1 = 0x000000000000000059e26bcea0d48bacd4f263f1acdb5c4f5763473177fffffe;
```

### T24

```solidity
uint256 private constant T24 = 0x1000000000000000000000000000000000000000000000000;
```

### MASK24

```solidity
uint256 private constant MASK24 = 0xffffffffffffffffffffffffffffffffffffffffffffffff;
```

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

| Name     | Type   | Description           |
| -------- | ------ | --------------------- |
| `<none>` | `bool` | bool sig verification |
| `<none>` | `bool` |                       |

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

### sqrt

returns square root of a uint256 value

```solidity
function sqrt(uint256 xx) internal pure returns (uint256 x, bool hasRoot);
```

**Parameters**

| Name | Type      | Description                          |
| ---- | --------- | ------------------------------------ |
| `xx` | `uint256` | the value to take the square root of |

**Returns**

| Name      | Type      | Description                                 |
| --------- | --------- | ------------------------------------------- |
| `x`       | `uint256` | the uint256 value of the root               |
| `hasRoot` | `bool`    | a bool indicating if there is a square root |

### inverse

inverts a uint256 value

```solidity
function inverse(uint256 a) internal pure returns (uint256);
```

**Parameters**

| Name | Type      | Description             |
| ---- | --------- | ----------------------- |
| `a`  | `uint256` | uint256 value to invert |

**Returns**

| Name     | Type      | Description                         |
| -------- | --------- | ----------------------------------- |
| `<none>` | `uint256` | uint256 of the value of the inverse |

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
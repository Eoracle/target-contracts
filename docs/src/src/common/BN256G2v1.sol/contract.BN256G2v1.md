# BN256G2v1

[Git Source](https://github.com/Eoracle/target-contracts/blob/836becbe8b5ae010bb5578a508ed70676be90884/src/common/BN256G2v1.sol)

**Inherits:** [IBN256G2](/src/interfaces/IBN256G2.sol/interface.IBN256G2.md)

_Adaptation of https://github.com/musalbas/solidity-BN256G2 to 0.6.0 and then 0.8.19_

## State Variables

### FIELD_MODULUS

```solidity
uint256 internal constant FIELD_MODULUS = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;
```

### TWISTBX

```solidity
uint256 internal constant TWISTBX = 0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5;
```

### TWISTBY

```solidity
uint256 internal constant TWISTBY = 0x9713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2;
```

### PTXX

```solidity
uint256 internal constant PTXX = 0;
```

### PTXY

```solidity
uint256 internal constant PTXY = 1;
```

### PTYX

```solidity
uint256 internal constant PTYX = 2;
```

### PTYY

```solidity
uint256 internal constant PTYY = 3;
```

### PTZX

```solidity
uint256 internal constant PTZX = 4;
```

### PTZY

```solidity
uint256 internal constant PTZY = 5;
```

### G2_NEG_X_RE

```solidity
uint256 public constant G2_NEG_X_RE = 0x198E9393920D483A7260BFB731FB5D25F1AA493335A9E71297E485B7AEF312C2;
```

### G2_NEG_X_IM

```solidity
uint256 public constant G2_NEG_X_IM = 0x1800DEEF121F1E76426A00665E5C4479674322D4F75EDADD46DEBD5CD992F6ED;
```

### G2_NEG_Y_RE

```solidity
uint256 public constant G2_NEG_Y_RE = 0x275dc4a288d1afb3cbb1ac09187524c7db36395df7be3b99e673b13a075a65ec;
```

### G2_NEG_Y_IM

```solidity
uint256 public constant G2_NEG_Y_IM = 0x1d9befcd05a5323e6da4d435f3b617cdb3af83285c2df711ef39c01571827f9d;
```

## Functions

### ecTwistAdd

Add two twist points

```solidity
function ecTwistAdd(
    uint256 pt1xx,
    uint256 pt1xy,
    uint256 pt1yx,
    uint256 pt1yy,
    uint256 pt2xx,
    uint256 pt2xy,
    uint256 pt2yx,
    uint256 pt2yy
)
    external
    view
    returns (uint256, uint256, uint256, uint256);
```

**Parameters**

| Name    | Type      | Description                   |
| ------- | --------- | ----------------------------- |
| `pt1xx` | `uint256` | Coefficient 1 of x on point 1 |
| `pt1xy` | `uint256` | Coefficient 2 of x on point 1 |
| `pt1yx` | `uint256` | Coefficient 1 of y on point 1 |
| `pt1yy` | `uint256` | Coefficient 2 of y on point 1 |
| `pt2xx` | `uint256` | Coefficient 1 of x on point 2 |
| `pt2xy` | `uint256` | Coefficient 2 of x on point 2 |
| `pt2yx` | `uint256` | Coefficient 1 of y on point 2 |
| `pt2yy` | `uint256` | Coefficient 2 of y on point 2 |

**Returns**

| Name     | Type      | Description                  |
| -------- | --------- | ---------------------------- |
| `<none>` | `uint256` | (pt3xx, pt3xy, pt3yx, pt3yy) |
| `<none>` | `uint256` |                              |
| `<none>` | `uint256` |                              |
| `<none>` | `uint256` |                              |

### ecTwistMul

Multiply a twist point by a scalar

```solidity
function ecTwistMul(
    uint256 s,
    uint256 pt1xx,
    uint256 pt1xy,
    uint256 pt1yx,
    uint256 pt1yy
)
    external
    view
    returns (uint256, uint256, uint256, uint256);
```

**Parameters**

| Name    | Type      | Description           |
| ------- | --------- | --------------------- |
| `s`     | `uint256` | Scalar to multiply by |
| `pt1xx` | `uint256` | Coefficient 1 of x    |
| `pt1xy` | `uint256` | Coefficient 2 of x    |
| `pt1yx` | `uint256` | Coefficient 1 of y    |
| `pt1yy` | `uint256` | Coefficient 2 of y    |

**Returns**

| Name     | Type      | Description                  |
| -------- | --------- | ---------------------------- |
| `<none>` | `uint256` | (pt2xx, pt2xy, pt2yx, pt2yy) |
| `<none>` | `uint256` |                              |
| `<none>` | `uint256` |                              |
| `<none>` | `uint256` |                              |

### getFieldModulus

Get the field modulus

```solidity
function getFieldModulus() external pure returns (uint256);
```

**Returns**

| Name     | Type      | Description       |
| -------- | --------- | ----------------- |
| `<none>` | `uint256` | The field modulus |

### submod

a-b mod n

```solidity
function submod(uint256 a, uint256 b, uint256 n) internal pure returns (uint256);
```

**Parameters**

| Name | Type      | Description    |
| ---- | --------- | -------------- |
| `a`  | `uint256` | First operand  |
| `b`  | `uint256` | Second operand |
| `n`  | `uint256` | modulus        |

**Returns**

| Name     | Type      | Description                 |
| -------- | --------- | --------------------------- |
| `<none>` | `uint256` | The result of the operation |

### \_fq2mul

FQ2\*FQ2 multiplication operation

```solidity
function _fq2mul(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256, uint256);
```

**Parameters**

| Name | Type      | Description                           |
| ---- | --------- | ------------------------------------- |
| `xx` | `uint256` | First FQ2 operands first coordinate   |
| `xy` | `uint256` | First FQ2 operands second coordinate  |
| `yx` | `uint256` | Second FQ2 operands first coordinate  |
| `yy` | `uint256` | Second FQ2 operands second coordinate |

**Returns**

| Name     | Type      | Description                |
| -------- | --------- | -------------------------- |
| `<none>` | `uint256` | [xx*yx-xy*yy, xx*yy+xy*yx] |
| `<none>` | `uint256` |                            |

### \_fq2muc

Fq2\*k multiplication operation

```solidity
function _fq2muc(uint256 xx, uint256 xy, uint256 k) internal pure returns (uint256, uint256);
```

**Parameters**

| Name | Type      | Description                    |
| ---- | --------- | ------------------------------ |
| `xx` | `uint256` | FQ2 operands first coordinate  |
| `xy` | `uint256` | FQ2 operands second coordinate |
| `k`  | `uint256` | scalar to multiply with        |

**Returns**

| Name     | Type      | Description  |
| -------- | --------- | ------------ |
| `<none>` | `uint256` | [xx*k, xy*k] |
| `<none>` | `uint256` |              |

### \_fq2sub

FQ2+FQ2 addition operation

FQ2-FQ2 subtraction operation

```solidity
function _fq2sub(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (uint256, uint256);
```

**Parameters**

| Name | Type      | Description                           |
| ---- | --------- | ------------------------------------- |
| `xx` | `uint256` | First FQ2 operands first coordinate   |
| `xy` | `uint256` | First FQ2 operands second coordinate  |
| `yx` | `uint256` | Second FQ2 operands first coordinate  |
| `yy` | `uint256` | Second FQ2 operands second coordinate |

**Returns**

| Name     | Type      | Description    |
| -------- | --------- | -------------- |
| `<none>` | `uint256` | [xx+yx, xy+yy] |
| `<none>` | `uint256` | [xx-yx, xy-yy] |

### \_fq2inv

FQ2/FQ2 division operation

1/FQ2 inverse operation

```solidity
function _fq2inv(uint256 x, uint256 y) internal view returns (uint256, uint256);
```

**Parameters**

| Name | Type      | Description                    |
| ---- | --------- | ------------------------------ |
| `x`  | `uint256` | FQ2 operands first coordinate  |
| `y`  | `uint256` | FQ2 operands second coordinate |

**Returns**

| Name     | Type      | Description               |
| -------- | --------- | ------------------------- |
| `<none>` | `uint256` | [xx, xy] \* Inv([yx, yy]) |
| `<none>` | `uint256` | Inv([xx, xy])             |

### \_isOnCurve

Checks if FQ2 is on G2

```solidity
function _isOnCurve(uint256 xx, uint256 xy, uint256 yx, uint256 yy) internal pure returns (bool);
```

**Parameters**

| Name | Type      | Description                           |
| ---- | --------- | ------------------------------------- |
| `xx` | `uint256` | First FQ2 operands first coordinate   |
| `xy` | `uint256` | First FQ2 operands second coordinate  |
| `yx` | `uint256` | Second FQ2 operands first coordinate  |
| `yy` | `uint256` | Second FQ2 operands second coordinate |

**Returns**

| Name     | Type   | Description              |
| -------- | ------ | ------------------------ |
| `<none>` | `bool` | True if the FQ2 is on G2 |

### \_modInv

Calculates the modular inverse of a over n

```solidity
function _modInv(uint256 a, uint256 n) internal view returns (uint256 result);
```

**Parameters**

| Name | Type      | Description                             |
| ---- | --------- | --------------------------------------- |
| `a`  | `uint256` | The operand to calculate the inverse of |
| `n`  | `uint256` | The modulus                             |

**Returns**

| Name     | Type      | Description |
| -------- | --------- | ----------- |
| `result` | `uint256` | Inv(a)modn  |

### \_fromJacobian

Converts a point from jacobian to affine

```solidity
function _fromJacobian(
    uint256 pt1xx,
    uint256 pt1xy,
    uint256 pt1yx,
    uint256 pt1yy,
    uint256 pt1zx,
    uint256 pt1zy
)
    internal
    view
    returns (uint256, uint256, uint256, uint256);
```

**Parameters**

| Name    | Type      | Description                        |
| ------- | --------- | ---------------------------------- |
| `pt1xx` | `uint256` | First point x real coordinate      |
| `pt1xy` | `uint256` | First point x imaginary coordinate |
| `pt1yx` | `uint256` | First point y real coordinate      |
| `pt1yy` | `uint256` | First point y imaginary coordinate |
| `pt1zx` | `uint256` | First point z real coordinate      |
| `pt1zy` | `uint256` | First point z imaginary coordinate |

**Returns**

| Name     | Type      | Description                                                                                                                                   |
| -------- | --------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `<none>` | `uint256` | pt2xx (x real affine coordinate) pt2xy (x imaginary affine coordinate) pt2yx (y real affine coordinate) pt1zy (y imaginary affine coordinate) |
| `<none>` | `uint256` |                                                                                                                                               |
| `<none>` | `uint256` |                                                                                                                                               |
| `<none>` | `uint256` |                                                                                                                                               |

### ecTwistAddJacobian

Adds two points in jacobian coordinates

```solidity
function ecTwistAddJacobian(
    uint256 pt1xx,
    uint256 pt1xy,
    uint256 pt1yx,
    uint256 pt1yy,
    uint256 pt1zx,
    uint256 pt1zy,
    uint256 pt2xx,
    uint256 pt2xy,
    uint256 pt2yx,
    uint256 pt2yy,
    uint256 pt2zx,
    uint256 pt2zy
)
    internal
    pure
    returns (uint256[6] memory pt3);
```

**Parameters**

| Name    | Type      | Description                         |
| ------- | --------- | ----------------------------------- |
| `pt1xx` | `uint256` | First point x real coordinate       |
| `pt1xy` | `uint256` | First point x imaginary coordinate  |
| `pt1yx` | `uint256` | First point y real coordinate       |
| `pt1yy` | `uint256` | First point y imaginary coordinate  |
| `pt1zx` | `uint256` | First point z real coordinate       |
| `pt1zy` | `uint256` | First point z imaginary coordinate  |
| `pt2xx` | `uint256` | Second point x real coordinate      |
| `pt2xy` | `uint256` | Second point x imaginary coordinate |
| `pt2yx` | `uint256` | Second point y real coordinate      |
| `pt2yy` | `uint256` | Second point y imaginary coordinate |
| `pt2zx` | `uint256` | Second point z real coordinate      |
| `pt2zy` | `uint256` | Second point z imaginary coordinate |

**Returns**

| Name  | Type         | Description           |
| ----- | ------------ | --------------------- |
| `pt3` | `uint256[6]` | = pt1+pt2 in jacobian |

### \_ecTwistDoubleJacobian

Doubls a point in jacobian coordinates

```solidity
function _ecTwistDoubleJacobian(
    uint256 pt1xx,
    uint256 pt1xy,
    uint256 pt1yx,
    uint256 pt1yy,
    uint256 pt1zx,
    uint256 pt1zy
)
    internal
    pure
    returns (uint256, uint256, uint256, uint256, uint256, uint256);
```

**Parameters**

| Name    | Type      | Description                  |
| ------- | --------- | ---------------------------- |
| `pt1xx` | `uint256` | Point x real coordinate      |
| `pt1xy` | `uint256` | Point x imaginary coordinate |
| `pt1yx` | `uint256` | Point y real coordinate      |
| `pt1yy` | `uint256` | Point y imaginary coordinate |
| `pt1zx` | `uint256` | Point z real coordinate      |
| `pt1zy` | `uint256` | Point z imaginary coordinate |

**Returns**

| Name     | Type      | Description                                                              |
| -------- | --------- | ------------------------------------------------------------------------ |
| `<none>` | `uint256` | pt2xx, pt2xy, pt2yx, pt2yy, pt2zx, pt2zy the coordinates of pt2 = 2\*pt1 |
| `<none>` | `uint256` |                                                                          |
| `<none>` | `uint256` |                                                                          |
| `<none>` | `uint256` |                                                                          |
| `<none>` | `uint256` |                                                                          |
| `<none>` | `uint256` |                                                                          |

### \_ecTwistMulJacobian

Doubls a point in jacobian coordinates

```solidity
function _ecTwistMulJacobian(
    uint256 d,
    uint256 pt1xx,
    uint256 pt1xy,
    uint256 pt1yx,
    uint256 pt1yy,
    uint256 pt1zx,
    uint256 pt1zy
)
    internal
    pure
    returns (uint256[6] memory pt2);
```

**Parameters**

| Name    | Type      | Description                       |
| ------- | --------- | --------------------------------- |
| `d`     | `uint256` | scalar to multiply the point with |
| `pt1xx` | `uint256` | Point x real coordinate           |
| `pt1xy` | `uint256` | Point x imaginary coordinate      |
| `pt1yx` | `uint256` | Point y real coordinate           |
| `pt1yy` | `uint256` | Point y imaginary coordinate      |
| `pt1zx` | `uint256` | Point z real coordinate           |
| `pt1zy` | `uint256` | Point z imaginary coordinate      |

**Returns**

| Name  | Type         | Description                                               |
| ----- | ------------ | --------------------------------------------------------- |
| `pt2` | `uint256[6]` | a point representing pt2 = d\*pt1 in jacobian coordinates |

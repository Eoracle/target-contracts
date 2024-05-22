# SafeMath

[Git Source](https://github.com/Eoracle/target-contracts/blob/ad9e9f7d406e96d8227780565e0953208bab6e55/src/libraries/SafeMath.sol)

_Wrappers over Solidity's arithmetic operations. NOTE: `SafeMath` is generally not needed starting with Solidity 0.8,
since the compiler now has built in overflow checking._

## Functions

### tryAdd

_Returns the addition of two unsigned integers, with an overflow flag. *Available since v3.4.*_

```solidity
function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256);
```

### trySub

_Returns the substraction of two unsigned integers, with an overflow flag. *Available since v3.4.*_

```solidity
function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256);
```

### tryMul

_Returns the multiplication of two unsigned integers, with an overflow flag. *Available since v3.4.*_

```solidity
function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256);
```

### tryDiv

_Returns the division of two unsigned integers, with a division by zero flag. *Available since v3.4.*_

```solidity
function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256);
```

### tryMod

_Returns the remainder of dividing two unsigned integers, with a division by zero flag. *Available since v3.4.*_

```solidity
function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256);
```

### add

\*Returns the addition of two unsigned integers, reverting on overflow. Counterpart to Solidity's `+` operator.
Requirements:

- Addition cannot overflow.\*

```solidity
function add(uint256 a, uint256 b) internal pure returns (uint256);
```

### sub

\*Returns the subtraction of two unsigned integers, reverting on overflow (when the result is negative). Counterpart to
Solidity's `-` operator. Requirements:

- Subtraction cannot overflow.\*

```solidity
function sub(uint256 a, uint256 b) internal pure returns (uint256);
```

### mul

_Returns the multiplication of two unsigned integers, reverting on overflow. Counterpart to Solidity's `_` operator.
Requirements:

- Multiplication cannot overflow.\*

```solidity
function mul(uint256 a, uint256 b) internal pure returns (uint256);
```

### div

\*Returns the integer division of two unsigned integers, reverting on division by zero. The result is rounded towards
zero. Counterpart to Solidity's `/` operator. Requirements:

- The divisor cannot be zero.\*

```solidity
function div(uint256 a, uint256 b) internal pure returns (uint256);
```

### mod

\*Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), reverting when dividing by zero.
Counterpart to Solidity's `%` operator. This function uses a `revert` opcode (which leaves remaining gas untouched)
while Solidity uses an invalid opcode to revert (consuming all remaining gas). Requirements:

- The divisor cannot be zero.\*

```solidity
function mod(uint256 a, uint256 b) internal pure returns (uint256);
```

### sub

\*Returns the subtraction of two unsigned integers, reverting with custom message on overflow (when the result is
negative). CAUTION: This function is deprecated because it requires allocating memory for the error message
unnecessarily. For custom revert reasons use [trySub](/src/libraries/SafeMath.sol/library.SafeMath.md#trysub).
Counterpart to Solidity's `-` operator. Requirements:

- Subtraction cannot overflow.\*

```solidity
function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256);
```

### div

\*Returns the integer division of two unsigned integers, reverting with custom message on division by zero. The result
is rounded towards zero. Counterpart to Solidity's `/` operator. Note: this function uses a `revert` opcode (which
leaves remaining gas untouched) while Solidity uses an invalid opcode to revert (consuming all remaining gas).
Requirements:

- The divisor cannot be zero.\*

```solidity
function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256);
```

### mod

\*Returns the remainder of dividing two unsigned integers. (unsigned integer modulo), reverting with custom message when
dividing by zero. CAUTION: This function is deprecated because it requires allocating memory for the error message
unnecessarily. For custom revert reasons use [tryMod](/src/libraries/SafeMath.sol/library.SafeMath.md#trymod).
Counterpart to Solidity's `%` operator. This function uses a `revert` opcode (which leaves remaining gas untouched)
while Solidity uses an invalid opcode to revert (consuming all remaining gas). Requirements:

- The divisor cannot be zero.\*

```solidity
function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256);
```

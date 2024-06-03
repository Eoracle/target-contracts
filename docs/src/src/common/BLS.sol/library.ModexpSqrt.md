# ModexpSqrt

[Git Source](https://github.com/Eoracle/target-contracts/blob/de89fc9e9bc7c046937883aa064d90812f1542cc/src/common/BLS.sol)

Compute $input^{(N + 1) / 4} mod N$ using Addition Chain method. Where N =
0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47 and (N + 1) / 4 =
0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52

## Functions

### run

computes square root by modular exponentiation

_Compute $input^{(N + 1) / 4} mod N$ using Addition Chain method_

```solidity
function run(uint256 t6) internal pure returns (uint256 t0);
```

**Parameters**

| Name | Type      | Description                             |
| ---- | --------- | --------------------------------------- |
| `t6` | `uint256` | the number to derive the square root of |

**Returns**

| Name | Type      | Description     |
| ---- | --------- | --------------- |
| `t0` | `uint256` | the square root |

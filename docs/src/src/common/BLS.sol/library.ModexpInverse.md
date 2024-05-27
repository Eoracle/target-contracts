# ModexpInverse

[Git Source](https://github.com/Eoracle/target-contracts/blob/836becbe8b5ae010bb5578a508ed70676be90884/src/common/BLS.sol)

## Functions

### run

computes inverse

_computes $input^(N - 2) mod N$ using Addition Chain method._

```solidity
function run(uint256 t2) internal pure returns (uint256 t0);
```

**Parameters**

| Name | Type      | Description                                |
| ---- | --------- | ------------------------------------------ |
| `t2` | `uint256` | the number to get the inverse of (uint256) |

**Returns**

| Name | Type      | Description           |
| ---- | --------- | --------------------- |
| `t0` | `uint256` | the inverse (uint256) |
